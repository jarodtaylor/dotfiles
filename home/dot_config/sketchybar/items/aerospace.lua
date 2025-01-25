local colors = require("colors")
local icons = require("icons")
local settings = require("settings")
local app_icons = require("helpers.app_icons")

local item_order = ""
local spaces_by_name = {}

local function getAppIcon(app_name)
  return app_icons[app_name] or app_icons["default"]
end

-- Simple JSON array parser for our specific case
local function parse_workspace_json(json_str)
  if not json_str then return {} end
  if type(json_str) == "table" then return json_str end
  
  local spaces = {}
  -- Remove brackets and split by commas
  local items = json_str:gsub("^%[", ""):gsub("%]$", ""):gsub("%s+", "")
  for item in items:gmatch("{[^}]+}") do
    local workspace = item:match('"workspace"%s*:%s*"([^"]+)"')
    local monitor_id = item:match('"monitor%-id"%s*:%s*(%d+)')
    if workspace and monitor_id then
      table.insert(spaces, {
        workspace = workspace,
        ["monitor-id"] = tonumber(monitor_id)
      })
    end
  end
  return spaces
end

-- Get monitor ID for a workspace based on Aerospace config and monitor count
local function get_monitor_id_for_workspace(workspace_name)
  -- Get the number of connected monitors
  local result = io.popen("aerospace list-monitors | wc -l"):read("*n")
  local monitor_count = tonumber(result) or 1
  
  -- If only one monitor is connected, all workspaces go to monitor 1
  if monitor_count == 1 then
    return 1
  end
  
  -- Multi-monitor setup: B and Z go to secondary, others to main
  if workspace_name == "B" or workspace_name == "Z" then
    return 2  -- Left monitor (DELL U2720QM (1))
  else
    return 1  -- Right monitor (DELL U2720QM (2))
  end
end

local function get_workspace_icon(workspace_name)
  -- Extract just the workspace name without any prefix
  local name = workspace_name:match("[^/]+$") or workspace_name
  return workspace_icons[name] or "󰆮"
end

sbar.exec("aerospace list-workspaces --all --format '%{workspace}%{monitor-id}' --json", function(spaces_json)
  local spaces = parse_workspace_json(spaces_json)
  
  -- Get all visible workspaces
  sbar.exec("aerospace list-workspaces --monitor all --visible", function(visible_workspaces)
    local visible_set = {}
    for workspace in visible_workspaces:gmatch("[^\r\n]+") do
      visible_set[workspace] = true
    end
    
    -- Group spaces by monitor
    local monitors = {}
    for _, space_info in ipairs(spaces) do
      local monitor_id = get_monitor_id_for_workspace(space_info.workspace)
      monitors[monitor_id] = monitors[monitor_id] or {}
      table.insert(monitors[monitor_id], space_info.workspace)
    end

    for monitor_id, monitor_spaces in pairs(monitors) do
      for _, space_name in ipairs(monitor_spaces) do
        local space = sbar.add("item", "space." .. space_name, {
          icon = { drawing = false },
          label = {
            drawing = true,
            string = space_name,
            color = visible_set[space_name] and colors.black or colors.white,
            font = {
              style = settings.font.style_map["SemiBold"],
              size = 12.0,
            },
            padding_right = 10,
            padding_left = 10
          },
          padding_right = 1,
          padding_left = 1,
          background = {
            color = visible_set[space_name] and colors.teal or colors.bg1,
            border_width = 0,
            height = 26,
          },
          associated_display = monitor_id
        })

        local space_bracket = sbar.add("bracket", { space.name }, {
          background = {
            color = colors.transparent,
            border_color = colors.bg2,
            height = 28,
            border_width = 0
          }
        })

        -- Padding space
        local space_padding = sbar.add("item", "space.padding." .. space_name, {
          width = settings.group_paddings,
          associated_display = monitor_id
        })

        space:subscribe("aerospace_workspace_change", function(env)
          local focused_workspace = env.FOCUSED_WORKSPACE
          local active_monitor = tonumber(env.ACTIVE_MONITOR)
          
          -- Update the space appearance based on visibility and focus
          space:set({
            label = { 
              color = (focused_workspace == space_name) and colors.black or colors.white,
            },
            background = { 
              color = (focused_workspace == space_name) and colors.teal or colors.bg1,
            }
          })
        end)

        space:subscribe("mouse.clicked", function()
          sbar.exec("aerospace workspace " .. space_name)
        end)

        item_order = item_order .. " " .. space.name .. " " .. space_padding.name
      end
    end
    sbar.exec("sketchybar --reorder " .. item_order .. " front_app menus")
  end)
end)