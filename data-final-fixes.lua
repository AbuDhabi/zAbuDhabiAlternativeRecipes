
local util = require("util")

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

-- Recalculate recycling recipes.
if mods and mods["quality"] then
  require("__quality__.data-updates")
end
