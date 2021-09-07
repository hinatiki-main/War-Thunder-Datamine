// Functions in this file called from C++ code

::is_last_load_controls_succeeded <- false

::load_controls <- function load_controls(blkOrPresetPath)
{
  local otherPreset = ::ControlsPreset(blkOrPresetPath)
  if (otherPreset.isLoaded && otherPreset.hotkeys.len() > 0)
  {
    ::g_controls_manager.setCurPreset(otherPreset)
    ::controls_fix_device_mapping()
    ::is_last_load_controls_succeeded = true
  }
  else
  {
    ::dagor.debug($"ControlsGlobals: Prevent setting incorrect preset: {blkOrPresetPath}")
    ::showInfoMsgBox($"{::loc("msgbox/errorLoadingPreset")}: {blkOrPresetPath}")
    ::is_last_load_controls_succeeded = false
  }
}

::save_controls_to_blk <- function save_controls_to_blk(blk)
{
  if (::g_controls_manager.getCurPreset().isLoaded)
  {
    ::g_controls_manager.getCurPreset().saveToBlk(blk)
    ::g_controls_manager.clearGuiOptions()
  }
}

::controls_fix_device_mapping <- function controls_fix_device_mapping()
{
  ::g_controls_manager.fixDeviceMapping()
  ::g_controls_manager.commitControls(false)
}
