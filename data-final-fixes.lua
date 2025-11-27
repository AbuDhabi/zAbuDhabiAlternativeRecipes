
local util = require("util")

-- Load and parse recipes to generate from startup setting.
local recipes_to_generate = {}
local recipes_setting = settings.startup["zadr-recipes-to-generate"]
if recipes_setting and recipes_setting.value and recipes_setting.value ~= "" then
  local rich_text = recipes_setting.value
  -- Parse Factorio rich text format: [recipe=name] tags separated by commas
  -- Recipe names can include letters, numbers, dashes, and underscores.
  for tag in string.gmatch(rich_text, "%[recipe=([%w%-_]+)%]") do
    table.insert(recipes_to_generate, tag)
  end
end

-- Log the converted recipe list.
util.log_serpent("[zAbuDhabiAlternativeRecipes] Recipes to generate:", recipes_to_generate)

-- Recalculate recycling recipes.
if mods and mods["quality"] then
  require("__quality__.data-updates")
end
