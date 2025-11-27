local util = {}

local DEBUG = false;

-- Logs data to factorio-current.log using serpent for serialization.
-- @param message: Optional prefix message
-- @param data: The data to serialize and log
function util.log_serpent(message, data)
  if not DEBUG then
    return;
  end
  local serialized = serpent.block(data, {comment = false})
  if message then
    log(message .. "\n" .. serialized)
  else
    log(serialized)
  end
end

return util

