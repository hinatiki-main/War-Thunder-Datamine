let { initGraphicsAutodetect, getGpuBenchmarkDuration, startGpuBenchmark,
  closeGraphicsAutodetect, getPresetFor60Fps, getPresetForMaxQuality,
  getPresetForMaxFPS, isGpuBenchmarkRunning } = require("gpuBenchmark")
let { setQualityPreset, canUseGraphicsOptions, onConfigApplyWithoutUiUpdate,
  localizaQualityPreset } = require("%scripts/options/systemOptions.nut")
let { secondsToString } = require("%scripts/time.nut")

let gpuBenchmarkPresets = [
  {
    presetId = "presetMaxQuality"
    getPresetNameFunc = getPresetForMaxQuality
    shortcut = "A"
  }
  {
    presetId = "presetMaxFPS"
    getPresetNameFunc = getPresetForMaxFPS
    shortcut = "X"
  }
  {
    presetId = "preset60Fps"
    getPresetNameFunc = getPresetFor60Fps
    shortcut = "Y"
  }
]

local class GpuBenchmarkWnd extends ::gui_handlers.BaseGuiHandlerWT {
  wndType = handlerType.MODAL
  sceneBlkName = "%gui/options/gpuBenchmark.blk"
  needUiUpdate = false
  timeEndBenchmark = -1

  function initScreen() {
    ::save_local_account_settings("gpuBenchmark/seen", true)
    initGraphicsAutodetect()
  }

  function updateProgressText() {
    let timeLeft = timeEndBenchmark - ::get_charserver_time_sec()
    if (timeLeft < 0) {
      scene.findObject("progressText").setValue("")
      return
    }

    let timeText = secondsToString(timeLeft, true, true)
    let progressText = ::loc("gpuBenchmark/progress", { timeLeft = timeText })
    scene.findObject("progressText").setValue(progressText)
  }

  function getPresetsView() {
    return gpuBenchmarkPresets.map(function(cfg) {
      let { presetId, getPresetNameFunc, shortcut } = cfg
      let presetName = getPresetNameFunc()
      return {
        presetName
        shortcut
        label = $"gpuBenchmark/{presetId}"
        presetText = localizaQualityPreset(presetName)
      }
    })
  }

  function onBenchmarkStart() {
    this.showSceneBtn("benchmarkStart", false)
    this.showSceneBtn("btnStart", false)
    this.showSceneBtn("waitAnimation", true)

    timeEndBenchmark = ::get_charserver_time_sec()
      + getGpuBenchmarkDuration().tointeger()
    updateProgressText()

    scene.findObject("progress_timer").setUserData(this)

    startGpuBenchmark()
  }

  function onUpdate(_, __) {
    if (timeEndBenchmark <= ::get_charserver_time_sec() && !isGpuBenchmarkRunning()) {
      scene.findObject("progress_timer").setUserData(null)
      onBenchmarkComplete()
      return
    }

    updateProgressText()
  }

  function onBenchmarkComplete() {
    this.showSceneBtn("waitAnimation", false)
    this.showSceneBtn("presetSelection", true)

    let view = { presets = getPresetsView() }
    let blk = ::handyman.renderCached("%gui/options/gpuBenchmarkPreset", view)
    guiScene.replaceContentFromText("resultsList", blk, blk.len(), this)
  }

  function onPresetApply(obj) {
    setQualityPreset(obj.presetName)
    if (!needUiUpdate)
      onConfigApplyWithoutUiUpdate()
    goBack()
  }

  function goBack() {
    closeGraphicsAutodetect()
    base.goBack()
  }
}

::gui_handlers.GpuBenchmarkWnd <- GpuBenchmarkWnd

let function canShowGpuBenchmarkWnd() {
  return canUseGraphicsOptions() && ::target_platform != "macosx"
}

let function checkShowGpuBenchmarkWnd() {
  if (!canShowGpuBenchmarkWnd())
    return

  if (::load_local_account_settings("gpuBenchmark/seen", false))
    return

  ::handlersManager.loadHandler(GpuBenchmarkWnd)
}

let function showGpuBenchmarkWnd() {
  if (!canShowGpuBenchmarkWnd())
    return

  ::handlersManager.loadHandler(GpuBenchmarkWnd, { needUiUpdate = true })
}

return {
  checkShowGpuBenchmarkWnd
  showGpuBenchmarkWnd
  canShowGpuBenchmarkWnd
}
