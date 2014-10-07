import math, strfmt

type 
  Vector*[T] = tuple[x, y, z: T]
  fVector* = Vector[float]
  iVector* = Vector[int]

# Binary operators
proc `+`*[T](a: Vector[T], b: T): Vector[T] {.noSideEffect, inline.} =
  # Adds two Vector[T] instances.
  result = (a.x + b,
            a.y + b,
            a.z + b)

proc `+`*[T](a, b: Vector[T]): Vector[T] {.noSideEffect, inline.} =
  # Adds two Vector[T] instances.
  result = (a.x + b.x,
            a.y + b.y,
            a.z + b.z)

proc `-`*[T](a: Vector[T]): Vector[T] {.noSideEffect, inline.} =
  # Subtracts two Vector[T] instances.
  result = (-a.x,
            -a.y,
            -a.z)

proc `*`*[T](a: Vector[T], b: T): Vector[T] {.noSideEffect, inline.} =
  # Multiplies all Vector[T] elements with a scalar.
  result.x = a.x * b
  result.y = a.y * b
  result.z = a.z * b

proc `/`*[T](a: Vector[T], b: T): Vector[T] {.noSideEffect, inline.} =
  # Divides all Vector[T] elements on a scalar.
  result.x = a.x / b
  result.y = a.y / b
  result.z = a.z / b

# In-place operators
proc `+=`*[T](a: var Vector[T], b: Vector[T]) {.inline.} =
  # Adds Vector[T] instance 'b' to Vector[T] instance 'a' in place.
  a.x = a.x + b.x
  a.y = a.y + b.y
  a.z = a.z + b.z

proc `+=`*[T](a: var Vector[T], b: T) {.inline.} =
  # Multiplies all Vector[T] elements with a scalar in place.
  a.x = a.x + b
  a.y = a.y + b
  a.z = a.z + b

# In-place operators
proc `*=`*[T](a: var Vector[T], b: T) {.inline.} =
  # Multiplies all Vector[T] elements with a scalar in place.
  a.x = a.x * b
  a.y = a.y * b
  a.z = a.z * b

proc `/=`*[T](a: var Vector[T], b: T) {.inline.} =
  # Multiplies all Vector[T] elements with a scalar in place.
  a.x = a.x / b
  a.y = a.y / b
  a.z = a.z / b

template `-`*[T](a, b: Vector[T]): expr = a + -b
template `-`*[T](b: T; a: Vector[T]): expr = -(a - b)

template `+`*[T](b: T; a: Vector[T]): expr = a + b

template `*`*[T](b: T; a: Vector[T]): expr = a * b

# In-place templates
template `-=`*[T](a, b: Vector[T]): expr = a += -b
template `-=`*[T](a: Vector[T], b: T): expr = a += -b
template `-=`*[T](b: T; a: Vector[T]): expr = a = b - a

template `+=`*[T](b: T; a: Vector[T]): expr = a = b + a

template `*=`*[T](b: T; a: Vector[T]): expr = a = b * a

template `-`*[T](a: vector; b: T): expr = a + -b

proc `*.`*[T](a, b: Vector[T]): T {.noSideEffect, inline.} =
  # Calculates the dot-product of two Vector[T] instances.
  result = a.x * b.x + a.y * b.y + a.z * b.z

proc `*+`*[T](a, b: Vector[T]): Vector[T] {.noSideEffect, inline.} =
  # Calculated the cross-product between two Vector[T] instances.
  result.x = a.y * b.z - b.y * a.z
  result.y = b.x * a.z - a.x * b.z 
  result.z = a.x * b.y - b.x * a.y

# Equality operators
proc `==`*[T](a, b: Vector[T]): bool {.noSideEffect, inline.} =
  # Compares two Vector[T] instances.
  if a.x != b.x:
    return false
  elif a.y != b.y:
    return false
  elif a.z != b.z:
    return false
  return true

proc `~=`*[T](a, b: Vector[T], tolerance: T = 1.0e-5): bool {.noSideEffect, inline.} =
  # Compares two Vector[T] instances for closeness.
  if abs(a.x - b.x) >= tolerance:
    return false
  if abs(a.y - b.y) >= tolerance:
    return false
  if abs(a.z - b.z) >= tolerance:
    return false

  return true

# Common Vector[T] operations
proc dot*[T](a, b: Vector[T]) : T {.noSideEffect, inline.} =
  # Calculates the dot-product of two Vector[T] instances.
  result = a *. b

proc norm*[T](a: Vector[T]): T {.inline.} =
  # Calculates the norm of a vector.
  result = math.sqrt(dot(a, a))

proc normalize*[T](a: Vector[T]): Vector[T] {.inline.} =
  # Returns a normalized Vector[T] instance.
  # The returned Vector[T] instance will have norm == 1
  var n = norm(a)
  result = a / n

proc copy*[T](a: Vector[T]): Vector[T] {.noSideEffect, inline.} =
  # Returns a copy of the input Vector[T] instance.
  result = a

proc `$`*[T](a: Vector[T]): string =
  var frmt = "6.f"
  result = "[" & $a.x.format(frmt) & ", " & $a.y.format(frmt) & ", " & $a.z.format(frmt) & "]"

when isMainModule:
  var
    x: fVector = (1.0, 0.0, 0.0)
    y: fVector = (0.0, 1.0, 0.0)
    z: fVector = (0.0, 0.0, 1.0)

  assert(-x == (-1.0, 0.0, 0.0))

  assert(x + y == (1.0, 1.0, 0.0))
  assert(x - y == (1.0, -1.0, 0.0))

  assert(x * 2.0 == (2.0, 0.0, 0.0))
  assert(x / 2.0 == (0.5, 0.0, 0.0))

  assert(x * 2.0 ~= (2.00000001, 0.0, 0.0))
  assert(x / 2.0 ~= (0.50000001, 0.0, 0.0))

  assert(dot(x, y) == 0.0)
  assert(x *. y == 0.0)

  assert(x *+ y == z)
  assert(norm(x) == 1.0)

  var tmp = copy(x)
  tmp *= 2.0
  assert(tmp != x)
  assert(tmp == (2.0, 0.0, 0.0))
  assert(x == (1.0, 0.0, 0.0))
  tmp += y
  assert(tmp == (2.0, 1.0, 0.0))
  tmp -= z
  assert(tmp == (2.0, 1.0, -1.0))
  tmp -= 2.0
  assert(tmp == (0.0, -1.0, -3.0))
  tmp += 2.0
  assert(tmp == (2.0, 1.0, -1.0))
  2.0 += tmp
  assert(tmp == (4.0, 3.0, 1.0))
  2.0 -= tmp
  assert(tmp == (-2.0, -1.0, 1.0))
  tmp /= 2.0
  echo tmp

  echo("All tests passed.")
  
