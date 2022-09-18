local logger = require("tools/logger")
local rime_api_helper = require("tools/rime_api_helper")

local tag_name = "punct"

local segmentor = {}

function segmentor.init(env)
  local context = env.engine.context
  local config = env.engine.schema.config
  env.notifier_option_full_shape = context.option_update_notifier:connect(function(ctx) -- 监听选项
    local full_shape_mode = ctx:get_option("full_shape")
    local current_punctuator_map = nil
    if(full_shape_mode) then
      -- full_shape
      env.full_shape_map = env.full_shape_map or rime_api_helper:get_config_item_value(config, "punctuator/full_shape")
      current_punctuator_map = env.full_shape_map
    else
      -- half_shape
      env.half_shape_map = env.half_shape_map or rime_api_helper:get_config_item_value(config, "punctuator/half_shape")
      current_punctuator_map = env.half_shape_map
    end
    env.current_punctuator_map = current_punctuator_map
  end)
end

function segmentor.fini(env)
  env.notifier_option_full_shape:disconnect()
end

function segmentor.func(segmentation, env)
  local current_punctuator_map = env.current_punctuator_map
  if(not current_punctuator_map) then
    return true
  end
  local input_active = segmentation.input
  local pos_comfirm = segmentation:get_confirmed_position() -- 下标0开始
  local input_waiting = string.sub(input_active, pos_comfirm+1)
  if(not input_waiting or #input_waiting ~= 1) then
    return true
  end
  local ch = string.byte(input_waiting)
  if(ch < 0x20 or ch >= 0x7f) then
    return true
  end
  -- 转换
  local key = current_punctuator_map[input_waiting]
  if(not key) then
    return true
  end
  local seg = Segment(pos_comfirm, pos_comfirm+#input_waiting)
  seg.tags =  Set({tag_name})
  segmentation:add_segment(seg)
  return true
end

return {
  segmentor = segmentor
}