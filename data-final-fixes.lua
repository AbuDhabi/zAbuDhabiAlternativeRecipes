
local util = require("util")

local function deepcopy(value)
  if type(value) ~= "table" then
    return value
  end

  local result = {}
  for k, v in pairs(value) do
    result[deepcopy(k)] = deepcopy(v)
  end

  return result
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
    local recipe_copy = deepcopy(recipe)
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
      local technology_copy = deepcopy(source_technology)
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
