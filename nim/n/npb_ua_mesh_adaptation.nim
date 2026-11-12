const Depth = 2
const Side = 4
const MaxCells = 64
const InvalidResult = -1.0e300

type Cell = object
  level, x, y, z: int

proc cellSize(cell: Cell): int = 1 shl (Depth - cell.level)

proc overlapsSource(cell: Cell, sx, sy, sz, radius: int): bool =
  let point = [sx, sy, sz]
  let lower = [cell.x, cell.y, cell.z]
  let size = cellSize(cell)
  var squared = 0
  for axis in 0 .. 2:
    var distance = 0
    if point[axis] < lower[axis]: distance = lower[axis] - point[axis]
    elif point[axis] > lower[axis] + size: distance = point[axis] - lower[axis] - size
    squared += distance * distance
  squared < radius * radius

proc neighboring(a, b: Cell): bool =
  let alo = [a.x, a.y, a.z]
  let blo = [b.x, b.y, b.z]
  let asize = cellSize(a)
  let bsize = cellSize(b)
  var touching = 0
  for axis in 0 .. 2:
    let ahi = alo[axis] + asize
    let bhi = blo[axis] + bsize
    if ahi == blo[axis] or bhi == alo[axis]: inc touching
    elif ahi <= blo[axis] or bhi <= alo[axis]: return false
  touching == 1 or touching == 2

proc splitCell(cells: var array[MaxCells, Cell], count: var int, index: int): bool =
  let parent = cells[index]
  if parent.level >= Depth or count + 7 > MaxCells: return false
  let childSize = cellSize(parent) div 2
  var i = count - 1
  while i > index:
    cells[i + 7] = cells[i]
    dec i
  var slot = index
  for bz in 0 .. 1:
    for by in 0 .. 1:
      for bx in 0 .. 1:
        cells[slot] = Cell(level: parent.level + 1, x: parent.x + bx * childSize,
          y: parent.y + by * childSize, z: parent.z + bz * childSize)
        inc slot
  count += 7
  true

proc balanced(cells: array[MaxCells, Cell], count: int): bool =
  for i in 0 ..< count:
    for j in i + 1 ..< count:
      if neighboring(cells[i], cells[j]) and abs(cells[i].level - cells[j].level) > 1: return false
  true

proc balanceMesh(cells: var array[MaxCells, Cell], count: var int): bool =
  while true:
    var coarse = -1
    block findViolation:
      for i in 0 ..< count:
        for j in i + 1 ..< count:
          if neighboring(cells[i], cells[j]) and abs(cells[i].level - cells[j].level) > 1:
            coarse = if cells[i].level < cells[j].level: i else: j
            break findViolation
    if coarse < 0: return true
    if not splitCell(cells, count, coarse): return false

proc isChild(cell: Cell, level, x, y, z, size: int): bool =
  cell.level == level and cell.x >= x and cell.x < x + size and cell.y >= y and cell.y < y + size and cell.z >= z and cell.z < z + size

proc coarsenOnce(cells: var array[MaxCells, Cell], count: var int, sx, sy, sz, radius: int): bool =
  for seed in 0 ..< count:
    let child = cells[seed]
    if child.level == 0: continue
    let parentLevel = child.level - 1
    let parentSize = 1 shl (Depth - parentLevel)
    let childSize = parentSize div 2
    let px = child.x div parentSize * parentSize
    let py = child.y div parentSize * parentSize
    let pz = child.z div parentSize * parentSize
    let parent = Cell(level: parentLevel, x: px, y: py, z: pz)
    if overlapsSource(parent, sx, sy, sz, radius): continue
    var found: array[8, int]
    for q in 0 .. 7: found[q] = -1
    for i in 0 ..< count:
      if isChild(cells[i], child.level, px, py, pz, parentSize):
        let bx = (cells[i].x - px) div childSize
        let by = (cells[i].y - py) div childSize
        let bz = (cells[i].z - pz) div childSize
        found[bx + 2 * by + 4 * bz] = i
    var complete = true
    for q in 0 .. 7:
      if found[q] < 0: complete = false
    if not complete: continue
    var safe = true
    for i in 0 ..< count:
      var sibling = false
      for q in 0 .. 7:
        if found[q] == i: sibling = true
      if not sibling and neighboring(parent, cells[i]) and abs(parentLevel - cells[i].level) > 1: safe = false
    if not safe: continue
    var compact: array[MaxCells, Cell]
    var compactCount = 0
    var inserted = false
    for i in 0 ..< count:
      var sibling = false
      for q in 0 .. 7:
        if found[q] == i: sibling = true
      if not sibling:
        compact[compactCount] = cells[i]
        inc compactCount
      elif not inserted:
        compact[compactCount] = parent
        inc compactCount
        inserted = true
    for i in 0 ..< compactCount: cells[i] = compact[i]
    count = compactCount
    return true
  false

proc lessCell(a, b: Cell): bool =
  if a.level != b.level: return a.level < b.level
  if a.z != b.z: return a.z < b.z
  if a.y != b.y: return a.y < b.y
  a.x < b.x

proc npb_ua_mesh_adaptation*(values: ptr UncheckedArray[int64], length: csize_t): float64
    {.cdecl, exportc: "npb_ua_mesh_adaptation".} =
  if values == nil or length < 9 or length > 261: return InvalidResult
  for q in 0 .. 2:
    if values[q] < 0 or values[q] > Side: return InvalidResult
  if values[3] < 1 or values[3] > Side or values[4] < 1 or values[4] > MaxCells: return InvalidResult
  let sx = int(values[0])
  let sy = int(values[1])
  let sz = int(values[2])
  let radius = int(values[3])
  var count = int(values[4])
  if length != csize_t(5 + 4 * count): return InvalidResult
  var cells: array[MaxCells, Cell]
  var covered: array[MaxCells, bool]
  for i in 0 ..< count:
    let lr = values[5 + 4 * i]
    let xr = values[6 + 4 * i]
    let yr = values[7 + 4 * i]
    let zr = values[8 + 4 * i]
    if lr < 0 or lr > Depth or xr < 0 or xr > Side or yr < 0 or yr > Side or zr < 0 or zr > Side: return InvalidResult
    let cell = Cell(level: int(lr), x: int(xr), y: int(yr), z: int(zr))
    let size = cellSize(cell)
    if cell.x + size > Side or cell.y + size > Side or cell.z + size > Side or
       cell.x mod size != 0 or cell.y mod size != 0 or cell.z mod size != 0: return InvalidResult
    cells[i] = cell
    for z in cell.z ..< cell.z + size:
      for y in cell.y ..< cell.y + size:
        for x in cell.x ..< cell.x + size:
          let q = x + Side * (y + Side * z)
          if covered[q]: return InvalidResult
          covered[q] = true
  for q in 0 ..< MaxCells:
    if not covered[q]: return InvalidResult
  if not balanced(cells, count): return InvalidResult
  var i = 0
  while i < count:
    if cells[i].level < Depth and overlapsSource(cells[i], sx, sy, sz, radius):
      if not splitCell(cells, count, i): return InvalidResult
    else: inc i
  if not balanceMesh(cells, count): return InvalidResult
  while coarsenOnce(cells, count, sx, sy, sz, radius): discard
  if not balanceMesh(cells, count): return InvalidResult
  for i in 1 ..< count:
    let key = cells[i]
    var j = i
    while j > 0 and lessCell(key, cells[j - 1]):
      cells[j] = cells[j - 1]
      dec j
    cells[j] = key
  var checksum = 0.0
  for q in 0 ..< count:
    let cell = cells[q]
    let code = cell.level * 1000 + cell.x * 100 + cell.y * 10 + cell.z
    checksum += float64(q + 1) * float64(code)
  checksum
