## Bare-bones SDL2 example 
import sdl2, sdl2/gfx 
import ray_tracer
import vector

discard SDL_Init(INIT_EVERYTHING)

var 
  window: PWindow
  render: PRenderer

window = CreateWindow("SDL Renderer", 100, 100, 400, 300, SDL_WINDOW_SHOWN)
render = CreateRenderer(window, -1, Renderer_Accelerated or Renderer_PresentVsync or Renderer_TargetTexture)

var
  evt: TEvent
  runGame = true
  image: TImage = render_scene()
  

while runGame:
  while pollEvent(evt):
    if evt.kind == QuitEvent:
      runGame = false
      break

  var maxval: float = 0
  for i in 0 .. 400:
    for j in 0 .. 300:
      var color: fVector = image[j][i]
      if color.x > maxval:
        maxval = color.x
      color *= 35.0

      render.setDrawColor(byte(color.x), byte(color.y), byte(color.z))
      render.drawPoint(cast[cint](i), cast[cint](j))

  echo maxval
  echo "drawing done"
  render.present

destroy render
destroy window

