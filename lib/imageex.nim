import
  sdl, sdl_gfx, math,
  common, image

type
  PImageEx* = ref TImageEx
  TImageEx* = object of TImage
    original*: PSurface
    originalPos: TPoint
    fAngle, fZoomX, fZoomY: float
    smooth*: cint


# TImageEx methods

proc init*(obj: PImageEx,
           smooth: cint,
          ) =
  obj.original = convertSurface(obj.surface,
                                obj.surface.format,
                                obj.surface.flags)
  obj.originalPos.x = obj.x
  obj.originalPos.y = obj.y
  obj.fAngle = 0.0
  obj.fZoomX = 1.0
  obj.fZoomY = 1.0
  obj.smooth = smooth

proc free*(obj: PImageEx) =
  PImage(obj).free()
  freeSurface(obj.original)


proc newImageEx*(filename: cstring,
                 x: int = 0,  # x draw offset
                 y: int = 0,  # y draw offset
                 smooth: cint = 1,  # smooth
                ): PImageEx =
  ## ``filename``: image file to load from.
  ##
  ## ``x``, ``y``: draw offset.
  ##
  ## ``smooth``: use smooth in transformations.
  new(result, free)
  init(PImage(result), filename, int16(x), int16(y))
  init(result, smooth)


proc newImageEx*(surface: PSurface,
                 x: int = 0,  # x draw offset
                 y: int = 0,  # y draw offset
                 smooth: cint = 1,  # smooth
                ): PImageEx =
  new(result, free)
  init(PImage(result), surface, int16(x), int16(y))
  init(result, smooth)


method updateRotZoom*(obj: PImageEx) =
  var pos: TPoint
  pos.x = obj.originalPos.x
  pos.y = obj.originalPos.y
  var width, height: int16
  # set x
  if obj.fZoomX == 1.0:
    width = int16(obj.original.w)
  else:
    width = int16(obj.original.w.toFloat * obj.fZoomX)
  # set y
  if obj.fZoomY == 1.0:
    height = int16(obj.original.h)
  else:
    height = int16(obj.original.h.toFloat * obj.fZoomY)
  # transform
  if obj.surface != nil: freeSurface(obj.surface)
  obj.surface = obj.original.zoomSurface(obj.fZoomX, obj.fZoomY, obj.smooth)
  if obj.fAngle != 0.0:
    var tmpSurface: PSurface = obj.surface.rotozoomSurface(obj.fAngle, 1.0, obj.smooth)
    freeSurface(obj.surface)
    obj.surface = convertSurface(tmpSurface,
                                 tmpSurface.format,
                                 tmpSurface.flags)
    freeSurface(tmpSurface)
  # calculate offset
  let angle = obj.fAngle * PI / 180.0
  obj.x = int16(-((pos.y.toFloat * obj.fZoomY - height / 2) * sin(angle) + (pos.x.toFloat * obj.fZoomX - width / 2) * cos(angle))) - int16((obj.surface.w - width) / 2 + width / 2)
  obj.y = int16(-((pos.y.toFloat * obj.fZoomY - height / 2) * cos(angle) - (pos.x.toFloat * obj.fZoomX - width / 2) * sin(angle))) - int16((obj.surface.h - height) / 2 + height / 2)

# Zooming

method zoomX*(obj: PImageEx): float {.inline.} =
  return obj.fZoomX

method zoomY*(obj: PImageEx): float {.inline.} =
  return obj.fZoomY

method `zoom=`*(obj: PImageEx, value: float) {.inline.} =
  obj.fZoomX = value
  obj.fZoomY = value
  obj.updateRotZoom()

method `zoomX=`*(obj: PImageEx, value: float) {.inline.} =
  obj.fZoomX = value
  obj.updateRotZoom()

method `zoomY=`*(obj: PImageEx, value: float) {.inline.} =
  obj.fZoomY = value
  obj.updateRotZoom()

# Rotation

method angle*(obj: PImageEx): float {.inline.} =
  return obj.fAngle

method `angle=`*(obj: PImageEx, value: float) {.inline.} =
  var val = value
  if value > 360.0: val = float(int(value) mod 360)
  elif value < 360.0: val = float(int(value) mod 360)
  obj.fAngle = val
  obj.updateRotZoom()

# Center offset

method centerOffset*(obj: PImageEx) {.inline.} =
  obj.originalPos.x = int16(obj.original.w / 2)
  obj.originalPos.y = int16(obj.original.h / 2)
  obj.updateRotZoom()

method centerOffsetX*(obj: PImageEx) {.inline.} =
  obj.originalPos.x = int16(obj.original.w / 2)
  obj.updateRotZoom()

method centerOffsetY*(obj: PImageEx) {.inline.} =
  obj.originalPos.y = int16(obj.original.h / 2)
  obj.updateRotZoom()

