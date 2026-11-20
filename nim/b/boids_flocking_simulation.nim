type
  I64Input = ptr UncheckedArray[int64]
  U8Output = ptr UncheckedArray[uint8]

const
  MaxBoids = 16
  SeparationScale = 256'i64

proc truncZero(numerator, denominator: int64): int64 =
  if numerator < 0: -((-numerator) div denominator) else: numerator div denominator

proc ceilSqrt(value: int64): int64 =
  var low = 0'i64
  var high = 4096'i64
  while low < high:
    let middle = (low + high) div 2
    if middle * middle < value: low = middle + 1 else: high = middle
  low

proc capVector(x, y, limit: int64): tuple[x, y: int64] =
  let squared = x*x + y*y
  if squared <= limit*limit: return (x, y)
  if limit == 0: return (0'i64, 0'i64)
  let length = ceilSqrt(squared)
  (truncZero(x*limit, length), truncZero(y*limit, length))

proc requestAcceleration(index, count: int, x, y, vx, vy: openArray[int64],
    radiusSquared, maxAcceleration: int64): tuple[x, y: int64] =
  var sx, sy, velocityX, velocityY, offsetX, offsetY = 0'i64
  var neighbors = 0'i64
  for other in 0 ..< count:
    if other == index: continue
    let dx = x[other] - x[index]
    let dy = y[other] - y[index]
    let distanceSquared = dx*dx + dy*dy
    if distanceSquared > radiusSquared: continue
    inc neighbors
    if distanceSquared == 0:
      sx += (if index < other: -SeparationScale else: SeparationScale)
    else:
      let length = ceilSqrt(distanceSquared)
      sx += truncZero(-dx*SeparationScale, length)
      sy += truncZero(-dy*SeparationScale, length)
    velocityX += vx[other]
    velocityY += vy[other]
    offsetX += dx
    offsetY += dy
  if neighbors == 0: return (0'i64, 0'i64)

  let separation = capVector(truncZero(sx, neighbors), truncZero(sy, neighbors), maxAcceleration)
  let alignment = capVector(truncZero(velocityX, neighbors) - vx[index],
    truncZero(velocityY, neighbors) - vy[index], maxAcceleration)
  let cohesion = capVector(truncZero(offsetX, neighbors), truncZero(offsetY, neighbors), maxAcceleration)
  let requests = [separation, alignment, cohesion]
  var ax, ay, used = 0'i64
  for request in requests:
    let remaining = maxAcceleration - used
    if remaining <= 0: break
    let length = ceilSqrt(request.x*request.x + request.y*request.y)
    if length == 0: continue
    if length <= remaining:
      ax += request.x
      ay += request.y
      used += length
    else:
      let trimmed = capVector(request.x, request.y, remaining)
      ax += trimmed.x
      ay += trimmed.y
      break
  (ax, ay)

proc storeI32Le(output: U8Output, offset: int, value: int64) =
  let bits = cast[uint32](int32(value))
  for byte in 0 ..< 4:
    output[offset + byte] = uint8((bits shr (byte * 8)) and 255'u32)

proc boids_flocking_simulation*(input: I64Input, length: csize_t, output: U8Output,
    outputCapacity: csize_t): int64 {.cdecl, exportc: "boids_flocking_simulation".} =
  if input == nil or length < 9 or length > 70: return -1
  let nValue = input[0]
  let steps = input[1]
  let radius = input[2]
  let maxSpeed = input[3]
  let maxAcceleration = input[4]
  if nValue < 1 or nValue > MaxBoids or steps < 0 or steps > 16
      or radius < 0 or radius > 128 or maxSpeed < 1 or maxSpeed > 32
      or maxAcceleration < 0 or maxAcceleration > 8
      or int(length) != 5 + 4 * int(nValue): return -1
  let n = int(nValue)
  var x, y, vx, vy, nextX, nextY, nextVx, nextVy: array[MaxBoids, int64]
  for i in 0 ..< n:
    x[i] = input[5 + 4*i]
    y[i] = input[6 + 4*i]
    vx[i] = input[7 + 4*i]
    vy[i] = input[8 + 4*i]
    if x[i] < -256 or x[i] > 256 or y[i] < -256 or y[i] > 256
        or vx[i] < -32 or vx[i] > 32 or vy[i] < -32 or vy[i] > 32
        or vx[i]*vx[i] + vy[i]*vy[i] > maxSpeed*maxSpeed: return -1
  let needed = 16 * n
  if output == nil or int(outputCapacity) < needed: return -2
  let radiusSquared = radius * radius
  for step in 0 ..< int(steps):
    for i in 0 ..< n:
      let acceleration = requestAcceleration(i, n, x, y, vx, vy, radiusSquared, maxAcceleration)
      let velocity = capVector(vx[i] + acceleration.x, vy[i] + acceleration.y, maxSpeed)
      nextVx[i] = velocity.x
      nextVy[i] = velocity.y
      nextX[i] = x[i] + velocity.x
      nextY[i] = y[i] + velocity.y
    for i in 0 ..< n:
      x[i] = nextX[i]
      y[i] = nextY[i]
      vx[i] = nextVx[i]
      vy[i] = nextVy[i]
  for i in 0 ..< n:
    storeI32Le(output, 16*i, x[i])
    storeI32Le(output, 16*i + 4, y[i])
    storeI32Le(output, 16*i + 8, vx[i])
    storeI32Le(output, 16*i + 12, vy[i])
  int64(needed)
