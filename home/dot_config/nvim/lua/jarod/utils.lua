local M = {}

function M.get_lazy_plugin_count()
  local path = vim.fn.stdpath('config') .. '/lazy-lock.json'
  local file = io.open(path, "r")

  if not file then
    print("Could not open lazy-lock.json")
    return 0
  end

  local content = file:read("*a")
  file:close()

  local success, data = pcall(vim.json.decode, content)
  if not success then
    print("Failed to parse JSON")
    return 0
  end

  -- Count the number of keys in the JSON object
  local count = 0
  for _ in pairs(data) do
    count = count + 1
  end

  return count
end

return M

