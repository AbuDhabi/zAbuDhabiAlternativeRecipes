local initial_settings = {}

-- Initial random seed for alternative recipe generation.
-- 0 can be treated in code as "no fixed seed / random each run".
initial_settings.random_seed = 0

-- Initial Factorio rich text string describing recipes to generate alternatives for.
-- Provide a concatenated list of [recipe=...] tags (no separators needed), e.g. "[recipe=boiler][recipe=iron-plate]".
-- Leave empty by default; your logic can interpret empty as "all supported recipes".
-- Set to all Factorio 2.0 intermediate recipes (items) excluding furnace recipes, barreling/unbarreling, and Space Age.
initial_settings.recipes_to_generate = "[recipe=iron-gear-wheel][recipe=copper-cable][recipe=electronic-circuit][recipe=advanced-circuit][recipe=processing-unit][recipe=engine-unit][recipe=electric-engine-unit][recipe=pipe][recipe=pipe-to-ground][recipe=iron-stick][recipe=plastic-bar][recipe=explosives][recipe=battery][recipe=low-density-structure][recipe=rocket-fuel]"

-- Initial Factorio rich text string describing ingredient groups for randomization.
-- Provide parenthesized groups containing concatenated [item=...] tags (no commas needed).
-- Example: "([item=iron-plate][item=copper-plate])([item=coal][item=solid-fuel])".
-- Each group below clusters ingredients with similar material, role, or shape.
initial_settings.ingredient_groups =
  "([item=iron-plate][item=copper-plate][item=steel-plate])" ..
  "([item=copper-cable][item=electronic-circuit][item=advanced-circuit][item=processing-unit])" ..
  "([item=iron-gear-wheel][item=engine-unit][item=electric-engine-unit])" ..
  "([item=iron-stick][item=pipe][item=pipe-to-ground])" ..
  "([item=plastic-bar][item=battery][item=explosives])" ..
  "([item=low-density-structure][item=rocket-fuel])"

return initial_settings


