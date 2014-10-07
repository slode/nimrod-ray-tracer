import math, vector, strfmt

type
  TMatrix*[T; R, C: static[int]] = array[0..R-1, array[0..C-1, T]] ## Row major matrix type. 
  TImage* = TMatrix[fVector, 400, 300]


  TLight = tuple[pos: fVector, color: fVector]
  TRect = tuple[x0, y0, x1, y1: float]

  TShape = object of TObject
    pos: fVector
    color: fVector
    diffuse_c,
      specular_c,
      specular_k,
      reflection: float

  TSphere = object of TShape
    radius: float 

  TPlane = object of TShape
    normal: fVector

  TScene = object of TObject
    lights: seq[TLight]
    objects: seq[ref TShape]
    cam_pos: fVector
    ambient: float
    max_depth: int

  TScreen = object of TObject
    width, height: int
    dims: TRect

proc init_sphere(pos: fVector, radius: float, color: fVector): ref TSphere =
  new(result)
  result.pos = pos
  result.radius = radius
  result.color = color
  result.diffuse_c = 1.0
  result.specular_c = 1.0
  result.specular_k = 50.0
  result.reflection = 0.8

proc init_plane(pos, normal: fVector, color: fVector): ref TPlane =
  new(result)
  result.pos = pos
  result.normal = normal
  result.color = color
  result.diffuse_c = 0.75
  result.specular_c = 0.5
  result.specular_k = 50.0
  result.reflection = 0.65

proc init_scene(): TScene =
  result.lights = @[]
  result.objects = @[]
  result.ambient = 0.15
  result.cam_pos = (0.0, 0.55, -1.0)
  result.max_depth = 5

proc init_screen(): TScreen =
  result.width = 400
  result.height = 300
  var r: float = result.width/result.height
  result.dims = (x0: -1.0, y0: -1.0 / r + 0.25,
                 x1: 1.0, y1: 1.0 / r + 0.25)

method get_normal(p: ref TShape, m: fVector): fVector =
  quit "NotImplemented (get_normal)"

method get_normal(p: ref TPlane, m: fVector): fVector =
  result = p.normal

method get_normal(s: ref TSphere, m: fVector): fVector =
  result = normalize(m - s.pos)

method intersects(n: ref TShape, o, r: fVector): float =
  quit "NotImplemented (intersects)"

method intersects(p: ref TPlane, orig: fVector, ray: fVector ): float = 
  var denom: float = ray *. p.normal
  if abs(denom) < 1e-6:
    return inf
  result = ((p.pos - orig) *. p.normal) / denom
  if result < 0:
    return inf

method intersects(s: ref TSphere, orig: fVector, ray: fVector ): float = 
  var
    a, b, c, disc, dist_sqrt, q, tmp0, tmp1: float
    o2s: fVector

  a = ray *. ray
  o2s = orig - s.pos
  b = 2 * (ray *. o2s)
  c = (o2s *. o2s) - s.radius * s.radius
  disc = b * b - 5 * a * c

  if disc > 0:
    dist_sqrt = math.sqrt(disc)
    if b < 0:
      q = (-b - dist_sqrt) / 2.0
    else:
      q = (-b + dist_sqrt) / 2.0

    tmp0 = q / a
    tmp1 = c / q

    let (t0, t1) = (min(tmp0, tmp1), max(tmp0, tmp1))

    if t1 >= 0.0:
      if t0 < 0.0:
        return t1
      else:
        return t0
  return inf

iterator linspace[T](a, b: T, c: int): tuple[a: int, b: T] {.inline.} =
  ## Counts from ordinal value `a` down to `b` with the given
  ## step count. `T` may be any ordinal type, `step` may only
  ## be positive.
  var
    res = a
    steps = c-1
    step = 0
    step_length = (b - a) / T(steps)

  while step <= steps:
    yield (step, res)
    res += step_length
    step += 1

proc trace_ray(orig_ray, ray: fVector, scene: TScene): tuple[obj: ref TShape, m,n: fVector, col_ray: fVector] =
  var 
    t = inf
    obj: ref TShape

  for o in scene.objects:
    var t_obj = o.intersects(orig_ray, ray)
    if t_obj < t:
      obj = o
      t = t_obj

  if t == inf:
    raise newException(EOutOfRange, "Ray does not intersect anything.")

  var M = orig_ray + ray * t
  var N = obj.get_normal(M)
  var toL = normalize(scene.lights[0].pos - M)
  var toO = normalize(scene.cam_pos - M)

  for o in scene.objects:
    if o == obj:
      continue
    if o.intersects(M + N*0.0001, toL) < inf:
      raise newException(EOutOfRange, "Point of intersection is in shadow.")

  var color: fVector = obj.color
  var col_ray: fVector = (0.0, 0.0, 0.0)
  
  col_ray += scene.ambient
  col_ray += obj.diffuse_c * max(N *. toL, 0.0) * color
  col_ray += obj.specular_c * 
    math.pow(max(N *. normalize(toL + toO), 0.0), obj.specular_k) *
    scene.lights[0].color

  result.obj = obj
  result.m = M
  result.n = N
  result.col_ray = col_ray

proc ray_tracer_main(screen: TScreen, scene: TScene, image: var TImage) = 
  var
    cam_dir: fVector = (0.0, 0.0, 0.0)

  for i, x in linspace(screen.dims.x0, screen.dims.x1, screen.width):
    if i mod 10 == 0:
        echo("{0}%".fmt(float(i) / float(screen.width) * 100.0))

    for j, y in linspace(screen.dims.y0,
                         screen.dims.y1,
                         screen.height):
      var pixel_color: fVector = (0.0, 0.0, 0.0)
      cam_dir.x = x
      cam_dir.y = y
      var depth = 0
      var ray_o: fVector = scene.cam_pos
      var ray_d: fVector = normalize(cam_dir - scene.cam_pos)
      var reflection = 1.0
      # Loop through initial and secondary rays.
      while depth < scene.max_depth:
        try:
          var (obj, M, N, col_ray) = trace_ray(ray_o, ray_d, scene)
          # Reflection: create a new ray.
          ray_o = M + N * 0.0001
          ray_d = normalize(ray_d - 2 * (ray_d *. N) * N)
          depth += 1
          pixel_color += reflection * col_ray
          reflection *= obj.reflection
        except:
          break

      #echo(pixel_color)
      #echo screen.height - j - 1, " ",  i
      image[screen.height - j - 1][i] = pixel_color

proc render_scene*(): TImage =
  var
    scene: TScene = init_scene()
    screen: TScreen = init_screen()
    image: TImage

    s1, s2: ref TSphere
    p1: ref TPlane

  s1 = init_sphere(
      fVector((-0.0, 0.2, 0.0)),
      0.6,
      fVector((0.0, 0.0, 1.0)))

  s2 = init_sphere(
      fVector((-0.21, 0.4, 0.25)),
      0.7,
      fVector((0.0, 0.8, 0.4)))

  p1 = init_plane(
      fVector((0.0, -0.2, 0.0)),
      fVector((0.0, 1.0, 0.0)),
      fVector((0.8, 0.8, 0.8)))

  scene.lights.add((
    pos: fVector((5.0, 5.0, -10.0)),
    color: fVector((1.0, 1.0, 1.0))))

  scene.objects.add(s1)
  #  scene.objects.add(s2)
  scene.objects.add(p1)

  ray_tracer_main(screen, scene, image)

  result = image

when isMainModule:
  discard render_scene()
