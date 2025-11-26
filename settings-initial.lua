local initial_settings = {}

-- Initial random seed for alternative recipe generation.
-- 0 can be treated in code as "no fixed seed / random each run".
initial_settings.random_seed = 0

-- Initial Factorio rich text string describing recipes to generate alternatives for.
-- This should be a comma-separated list using [recipe=...] tags, e.g. "[recipe=boiler],[recipe=iron-plate]".
-- Leave empty by default; your logic can interpret empty as "all supported recipes".
initial_settings.recipes_to_generate = ""

-- Initial Factorio rich text string describing ingredient groups for randomization.
-- This should be a semicolon-separated list of groups, where each group is a comma-separated list of [item=...] tags.
-- Example: "[item=iron-plate],[item=copper-plate];[item=coal],[item=solid-fuel]".
initial_settings.ingredient_groups = ""

return initial_settings


