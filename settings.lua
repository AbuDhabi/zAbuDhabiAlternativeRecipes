local initial_settings = require("settings-initial")

data:extend({
  -- Random seed for alternative recipe generation.
  {
    type = "int-setting",
    name = "zadr-random-seed",
    setting_type = "startup",
    default_value = initial_settings.random_seed,
    minimum_value = 0,
    maximum_value = 2147483647,
    order = "a[random-seed]"
  },

  -- Factorio rich text specifying recipes that will get alternative versions generated.
  -- Expects a comma-separated list of [recipe=...] tags, e.g. "[recipe=boiler],[recipe=iron-plate]".
  {
    type = "string-setting",
    name = "zadr-recipes-to-randomize",
    setting_type = "startup",
    default_value = initial_settings.recipes_to_generate,
    allow_blank = true,
    order = "b[recipes-to-randomize]"
  },

  -- Factorio rich text specifying ingredient groups within which randomization can swap ingredients.
  -- Expects a semicolon-separated list of groups, where each group is a comma-separated list of [item=...] tags.
  -- Example: "[item=iron-plate],[item=copper-plate];[item=coal],[item=solid-fuel]".
  {
    type = "string-setting",
    name = "zadr-ingredient-groups",
    setting_type = "startup",
    default_value = initial_settings.ingredient_groups,
    allow_blank = true,
    order = "c[ingredient-groups]"
  }
})

