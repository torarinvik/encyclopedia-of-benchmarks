import std/math

const MinBodies = 2
const MaxBodies = 16
const MaxNodes = 1024
const MaxDepth = 16

type
  BhBody = object
    position: array[3, float64]
    mass: float64
  BhCell = object
    body: int
    child: array[8, int]
    mass: float64
    center: array[3, float64]
  BhContext = object
    bodies: array[MaxBodies, BhBody]
    cells: array[MaxNodes, BhCell]
    used: int

proc octant(position, center: array[3, float64]): int =
  (if position[0] >= center[0]: 1 else: 0) or
  (if position[1] >= center[1]: 2 else: 0) or
  (if position[2] >= center[2]: 4 else: 0)

proc newCell(ctx: var BhContext): int =
  if ctx.used >= MaxNodes: return -1
  result = ctx.used
  inc ctx.used
  ctx.cells[result].body = -1
  for child in 0 ..< 8: ctx.cells[result].child[child] = -1

proc insertBody(ctx: var BhContext, cellIndex, bodyIndex: int,
                center: array[3, float64], half: float64, depth: int): bool =
  let oldBody = ctx.cells[cellIndex].body
  if oldBody == -1:
    ctx.cells[cellIndex].body = bodyIndex
    return true
  if depth >= MaxDepth: return false
  if oldBody >= 0: ctx.cells[cellIndex].body = -2
  let itemCount = if oldBody >= 0: 2 else: 1
  for itemIndex in 0 ..< itemCount:
    let whichBody = if oldBody >= 0 and itemIndex == 0: oldBody else: bodyIndex
    let child = octant(ctx.bodies[whichBody].position, center)
    if ctx.cells[cellIndex].child[child] < 0:
      let created = newCell(ctx)
      if created < 0: return false
      ctx.cells[cellIndex].child[child] = created
    var nextCenter: array[3, float64]
    for axis in 0 ..< 3:
      let direction = if (child and (1 shl axis)) != 0: half / 2.0 else: -half / 2.0
      nextCenter[axis] = center[axis] + direction
    if not insertBody(ctx, ctx.cells[cellIndex].child[child], whichBody, nextCenter, half / 2.0, depth + 1): return false
  true

proc aggregate(ctx: var BhContext, cellIndex: int) =
  let body = ctx.cells[cellIndex].body
  if body >= 0:
    ctx.cells[cellIndex].mass = ctx.bodies[body].mass
    ctx.cells[cellIndex].center = ctx.bodies[body].position
    return
  var weighted: array[3, float64]
  ctx.cells[cellIndex].mass = 0.0
  for child in 0 ..< 8:
    let childIndex = ctx.cells[cellIndex].child[child]
    if childIndex < 0: continue
    aggregate(ctx, childIndex)
    ctx.cells[cellIndex].mass += ctx.cells[childIndex].mass
    for axis in 0 ..< 3:
      weighted[axis] += ctx.cells[childIndex].mass * ctx.cells[childIndex].center[axis]
  for axis in 0 ..< 3: ctx.cells[cellIndex].center[axis] = weighted[axis] / ctx.cells[cellIndex].mass

proc interact(mass: float64, position, query: array[3, float64], epsSq: float64,
              potential: var float64, acceleration: var array[3, float64]) =
  var d: array[3, float64]
  var r2 = epsSq
  for axis in 0 ..< 3:
    d[axis] = position[axis] - query[axis]
    r2 += d[axis] * d[axis]
  let contribution = mass / sqrt(r2)
  potential -= contribution
  let scale = contribution / r2
  for axis in 0 ..< 3: acceleration[axis] += d[axis] * scale

proc walk(ctx: var BhContext, cellIndex: int, side, thetaSq: float64,
          query: array[3, float64], epsSq: float64,
          potential: var float64, acceleration: var array[3, float64]) =
  let cell = ctx.cells[cellIndex]
  if cell.body >= 0:
    let body = ctx.bodies[cell.body]
    interact(body.mass, body.position, query, epsSq, potential, acceleration)
    return
  var distanceSq = 0.0
  for axis in 0 ..< 3:
    let d = cell.center[axis] - query[axis]
    distanceSq += d * d
  if thetaSq * distanceSq < side * side:
    for child in 0 ..< 8:
      if cell.child[child] >= 0:
        walk(ctx, cell.child[child], side / 2.0, thetaSq, query, epsSq, potential, acceleration)
  else:
    interact(cell.mass, cell.center, query, epsSq, potential, acceleration)

proc olden_bh*(input: ptr UncheckedArray[float64], inputLength: csize_t,
    output: ptr UncheckedArray[float64], outputCapacity: csize_t): int64
    {.cdecl, exportc: "olden_bh".} =
  if input.isNil or inputLength < csize_t(6): return -1
  let requestedCount = input[0]
  let theta = input[1]
  let softening = input[2]
  if not (requestedCount >= float64(MinBodies) and requestedCount <= float64(MaxBodies)) or
      float64(int(requestedCount)) != requestedCount or not (theta >= 0.0 and theta <= 2.0) or
      not (softening >= 0.0 and softening <= 1.0): return -1
  let count = int(requestedCount)
  if inputLength != csize_t(6 + 4 * count): return -1
  var query: array[3, float64]
  for axis in 0 ..< 3:
    query[axis] = input[3 + axis]
    if not (query[axis] >= -32.0 and query[axis] <= 32.0): return -1
  var ctx: BhContext
  var minima: array[3, float64] = [32.0, 32.0, 32.0]
  var maxima: array[3, float64] = [-32.0, -32.0, -32.0]
  for body in 0 ..< count:
    for axis in 0 ..< 3:
      let value = input[6 + 4 * body + axis]
      if not (value >= -32.0 and value <= 32.0) or float64(int(value)) != value: return -1
      ctx.bodies[body].position[axis] = value
      if value < minima[axis]: minima[axis] = value
      if value > maxima[axis]: maxima[axis] = value
    let mass = input[9 + 4 * body]
    if not (mass >= 1.0 and mass <= 16.0): return -1
    ctx.bodies[body].mass = mass
  for a in 0 ..< count:
    for b in a + 1 ..< count:
      if ctx.bodies[a].position == ctx.bodies[b].position: return -1
  var inside = true
  for axis in 0 ..< 3:
    if query[axis] < minima[axis] or query[axis] > maxima[axis]: inside = false
  if inside: return -1
  if output.isNil or outputCapacity < csize_t(4): return -2
  let side = max(maxima[0] - minima[0], max(maxima[1] - minima[1], maxima[2] - minima[2]))
  if side <= 0.0: return -1
  var center: array[3, float64]
  for axis in 0 ..< 3: center[axis] = (minima[axis] + maxima[axis]) / 2.0
  let root = newCell(ctx)
  for body in 0 ..< count:
    if not insertBody(ctx, root, body, center, side / 2.0, 0): return -1
  aggregate(ctx, root)
  var potential = 0.0
  var acceleration: array[3, float64]
  walk(ctx, root, side, theta * theta, query, softening * softening, potential, acceleration)
  output[0] = potential
  output[1] = acceleration[0]
  output[2] = acceleration[1]
  output[3] = acceleration[2]
  4
