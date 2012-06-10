import
  sdl, sdl_image, common

type
  PMask* = ref TMask
  TMask* = object of TObject
    x*, y*: int16
    w*, h*: UInt16
    data*: seq[seq[bool]]

proc init*(obj: PMask,
           filename: cstring,
           x: int16 = 0'i16,
           y: int16 = 0'i16,
          ) =
  obj.x = x
  obj.y = y
  if filename != nil:
    let surface: PSurface = do(imgLoad(filename))
    let format = surface.format
    obj.w = UInt16(surface.w)
    obj.h = UInt16(surface.h)
    let pixels: PByteArray = cast[PByteArray](surface.pixels)
    do(lockSurface(surface))
    
    var offset: int
    var pixel, temp: UInt32
    var alpha: int16
    obj.data = @[]
    for y in 0..surface.h-1:
      obj.data.add(@[])
      #write(stdout, "\n")  # DEBUG: Uncomment to output mask
      for x in 0..surface.w-1:
        offset = y * surface.pitch + x * format.BytesPerPixel + 3
        pixel = pixels[offset]
        temp = pixel and format.Amask
        temp = temp shr format.Ashift
        alpha = int16(temp shl format.Aloss)
        if alpha < 127:
          obj.data[obj.data.high].add(false)
          #write(stdout, " ") # DEBUG: Uncomment to output mask
        else:
          obj.data[obj.data.high].add(true)
          #write(stdout, "X")  # DEBUG: Uncomment to output mask
        
    unlockSurface(surface)
    freeSurface(surface)


proc newMask*(filename: cstring,
              x: int = 0,
              y: int = 0,
             ): PMask =
  new(result)
  init(result, filename, int16(x), int16(y))


method getRect*(obj: PMask): TRect =
  result.x = obj.x
  result.y = obj.y
  result.w = obj.w
  result.h = obj.h