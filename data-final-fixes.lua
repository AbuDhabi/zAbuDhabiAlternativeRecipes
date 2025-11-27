
local util = require("util")

local icon_source_categories = {
  "item",
  "tool",
  "gun",
  "ammo",
  "armor",
  "capsule",
  "module",
  "item-with-entity-data",
  "item-with-label",
  "item-with-inventory",
  "rail-planner",
  "selection-tool",
  "copy-paste-tool",
  "blueprint",
  "deconstruction-item",
  "blueprint-book",
  "repair-tool",
  "item-with-tags",
  "upgrade-item",
  "spidertron-remote"
}

local function copy_icons(target, source)
  if source.icons then
    target.icons = table.deepcopy(source.icons)
    target.icon = nil
    target.icon_size = nil
    target.icon_mipmaps = nil
  elseif source.icon then
    target.icon = source.icon
    target.icon_size = source.icon_size
    target.icon_mipmaps = source.icon_mipmaps
    target.icons = nil
  end
end

local function extract_products(proto)
  if proto.results then
    return proto.results
  end

  if proto.result then
    return {
      {
        type = proto.result_type or "item",
        name = proto.result,
        amount = proto.result_count or 1
      }
    }
  end

  return nil
end

local function determine_primary_product(recipe)
  if recipe.main_product then
    return {
      name = recipe.main_product,
      type = recipe.main_product_type or (recipe.result_type or "item")
    }
  end

  local products = extract_products(recipe)
  if not products and recipe.normal then
    products = extract_products(recipe.normal)
  end
  if not products and recipe.expensive then
    products = extract_products(recipe.expensive)
  end

  if not products or not products[1] then
    return nil
  end

  local first = products[1]
  local name = first.name or first[1]
  local type = first.type or first[3] or first[2] and first[2].type or "item"

  if not name then
    return nil
  end

  return {name = name, type = type}
end

local function find_product_icon_source(recipe)
  local product = determine_primary_product(recipe)
  if not product then
    return nil
  end

  local product_name = product.name
  local product_type = product.type or "item"

  if product_type == "fluid" then
    return data.raw.fluid and data.raw.fluid[product_name]
  end

  for _, category in ipairs(icon_source_categories) do
    local prototype = data.raw[category] and data.raw[category][product_name]
    if prototype and (prototype.icons or prototype.icon) then
      return prototype
    end
  end

  return nil
end

-- Load and parse recipes to generate from startup setting.
local recipes_to_generate = {}
local recipes_setting = settings.startup["zadr-recipes-to-generate"]
if recipes_setting and recipes_setting.value and recipes_setting.value ~= "" then
  local rich_text = recipes_setting.value
  -- Parse Factorio rich text format: concatenated [recipe=name] tags
  -- Recipe names can include letters, numbers, dashes, and underscores.
  for tag in string.gmatch(rich_text, "%[recipe=([%w%-_]+)%]") do
    table.insert(recipes_to_generate, tag)
  end
end

-- Log the converted recipe list.
util.log_serpent("[zAbuDhabiAlternativeRecipes] Recipes to generate:", recipes_to_generate)

-- Load and parse ingredient groups into a keyed table of arrays.
local ingredient_groups = {}
local groups_setting = settings.startup["zadr-ingredient-groups"]
if groups_setting and groups_setting.value and groups_setting.value ~= "" then
  local groups_text = groups_setting.value
  local group_index = 1

  -- Each group is parenthesized, containing concatenated [item=name] tags.
  for group in string.gmatch(groups_text, "%(([^%(%)]*)%)") do
    local items = {}
    for item in string.gmatch(group, "%[item=([%w%-_]+)%]") do
      table.insert(items, item)
    end

    if #items > 0 then
      ingredient_groups["group_" .. group_index] = items
      group_index = group_index + 1
    end
  end
end

util.log_serpent("[zAbuDhabiAlternativeRecipes] Ingredient groups:", ingredient_groups)

-- Build a lookup for the recipes we care about.
local recipe_target_lookup = {}
for _, recipe_name in ipairs(recipes_to_generate) do
  recipe_target_lookup[recipe_name] = true
end

-- Find technologies that unlock our target recipes and map them.
local recipe_technology_map = {}
for _, technology in pairs(data.raw.technology or {}) do
  local effects = technology.effects
  if effects then
    for _, effect in pairs(effects) do
      if effect.type == "unlock-recipe" and effect.recipe and recipe_target_lookup[effect.recipe] then
        local bucket = recipe_technology_map[effect.recipe]
        if not bucket then
          bucket = {}
          recipe_technology_map[effect.recipe] = bucket
        end
        table.insert(bucket, technology.name)
      end
    end
  end
end

util.log_serpent("[zAbuDhabiAlternativeRecipes] Recipe technology map:", recipe_technology_map)


local new_recipes = {}
local new_technologies = {}

for _, recipe_name in ipairs(recipes_to_generate) do
  local recipe = data.raw.recipe[recipe_name]
  local unlockers = recipe_technology_map[recipe_name]

  if recipe and unlockers and #unlockers > 0 then
    local alternative_recipe_name = recipe_name .. "-alternative"
    local recipe_copy = table.deepcopy(recipe)
    recipe_copy.name = alternative_recipe_name
    recipe_copy.enabled = false

    if recipe_copy.normal then
      recipe_copy.normal.enabled = false
    end

    if recipe_copy.expensive then
      recipe_copy.expensive.enabled = false
    end

    recipe_copy.localised_name = {"", {"recipe-name." .. recipe_name}, " (alternative)"}
    table.insert(new_recipes, recipe_copy)

    local source_technology = data.raw.technology[unlockers[1]]
    if source_technology then
      local technology_copy = table.deepcopy(source_technology)
      technology_copy.name = alternative_recipe_name
      technology_copy.effects = {
        {
          type = "unlock-recipe",
          recipe = alternative_recipe_name
        }
      }

      local prereq_lookup = {}
      technology_copy.prerequisites = {}
      for _, tech_name in ipairs(unlockers) do
        if data.raw.technology[tech_name] and not prereq_lookup[tech_name] then
          table.insert(technology_copy.prerequisites, tech_name)
          prereq_lookup[tech_name] = true
        end
      end

      technology_copy.localised_name = {"", {"technology-name." .. source_technology.name}, " (alternative)"}
      technology_copy.order = (source_technology.order or "z") .. "-alternative"
      -- Share recipe icons with technology when the recipe (or its primary product) defines them; otherwise keep existing.
      if recipe.icons or recipe.icon then
        copy_icons(technology_copy, recipe)
      else
        local product_source = find_product_icon_source(recipe)
        if product_source then
          copy_icons(technology_copy, product_source)
        end
      end

      -- Double research cost while keeping ingredient types and research time.
      if technology_copy.unit and technology_copy.unit.ingredients then
        for _, ingredient in pairs(technology_copy.unit.ingredients) do
          if ingredient[2] then
            ingredient[2] = ingredient[2] * 2
          elseif ingredient.amount then
            ingredient.amount = ingredient.amount * 2
          end
        end
      end

      table.insert(new_technologies, technology_copy)
    end
  end
end

if #new_recipes > 0 then
  data:extend(new_recipes)
end

if #new_technologies > 0 then
  data:extend(new_technologies)
end

-- Recalculate recycling recipes.
if mods and mods["quality"] then
  require("__quality__.data-updates")
end
