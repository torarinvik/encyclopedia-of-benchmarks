const MaxCells = 16
const MaxTiles = 4
const MaxParseableInputLength = 56

type
  DomainArray = array[MaxCells, uint8]
  CompatibilityArray = array[4 * MaxTiles, uint8]
  WeightArray = array[MaxTiles, uint8]
  DrawArray = array[MaxCells, uint16]

proc popcountSmall(mask: uint8): int =
  var bits = mask
  while bits != 0:
    bits = bits and (bits - 1)
    inc result

proc propagate(domains: var DomainArray, compatibility: CompatibilityArray,
               width, height, tileCount, startCell: int, seedAll: bool): bool =
  let cellCount = width * height
  var queue: array[MaxCells, int]
  var inQueue: array[MaxCells, bool]
  var head = 0
  var tail = 0
  var queued = 0
  if seedAll:
    for cell in 0 ..< cellCount:
      queue[tail] = cell
      tail = (tail + 1) mod cellCount
      inc queued
      inQueue[cell] = true
  else:
    queue[tail] = startCell
    tail = (tail + 1) mod cellCount
    inc queued
    inQueue[startCell] = true

  while queued != 0:
    let source = queue[head]
    head = (head + 1) mod cellCount
    dec queued
    inQueue[source] = false
    let row = source div width
    let column = source mod width
    for direction in 0 ..< 4:
      var neighbor = 0
      var hasNeighbor = false
      if direction == 0 and row != 0:
        neighbor = source - width
        hasNeighbor = true
      elif direction == 1 and column + 1 < width:
        neighbor = source + 1
        hasNeighbor = true
      elif direction == 2 and row + 1 < height:
        neighbor = source + width
        hasNeighbor = true
      elif direction == 3 and column != 0:
        neighbor = source - 1
        hasNeighbor = true
      if not hasNeighbor: continue
      var supported = 0'u8
      for tile in 0 ..< tileCount:
        let bit = uint8(1 shl tile)
        if (domains[source] and bit) != 0:
          supported = supported or compatibility[direction * tileCount + tile]
      let reduced = domains[neighbor] and supported
      if reduced == domains[neighbor]: continue
      domains[neighbor] = reduced
      if reduced == 0: return false
      if not inQueue[neighbor]:
        queue[tail] = neighbor
        tail = (tail + 1) mod cellCount
        inc queued
        inQueue[neighbor] = true
  true

proc wave_function_collapse_simple_tiled*(input: ptr UncheckedArray[int64],
                                          inputLength: csize_t): int64 {.cdecl, exportc: "wave_function_collapse_simple_tiled".} =
  if input == nil or inputLength < 3 or inputLength > MaxParseableInputLength: return -1
  if input[0] < 1 or input[0] > 4 or input[1] < 1 or input[1] > 4 or input[2] < 1 or input[2] > MaxTiles: return -1
  let width = int(input[0])
  let height = int(input[1])
  let tileCount = int(input[2])
  let cellCount = width * height
  if int(inputLength) != 3 + 2 * cellCount + 5 * tileCount: return -1
  let fullMask = uint8((1 shl tileCount) - 1)
  var domains: DomainArray
  var weights: WeightArray
  var compatibility: CompatibilityArray
  var draws: DrawArray
  var position = 3
  for cell in 0 ..< cellCount:
    let value = input[position]
    if value < 1 or value > int64(fullMask): return -1
    domains[cell] = uint8(value)
    inc position
  for tile in 0 ..< tileCount:
    let value = input[position]
    if value < 1 or value > 4: return -1
    weights[tile] = uint8(value)
    inc position
  for direction in 0 ..< 4:
    for tile in 0 ..< tileCount:
      let value = input[position]
      if value < 0 or value > int64(fullMask): return -1
      compatibility[direction * tileCount + tile] = uint8(value)
      inc position
  for cell in 0 ..< cellCount:
    let value = input[position]
    if value < 0 or value > 65535: return -1
    draws[cell] = uint16(value)
    inc position

  for first in 0 ..< tileCount:
    for second in 0 ..< tileCount:
      let north = (compatibility[first] and uint8(1 shl second)) != 0
      let southReverse = (compatibility[2 * tileCount + second] and uint8(1 shl first)) != 0
      let east = (compatibility[tileCount + first] and uint8(1 shl second)) != 0
      let westReverse = (compatibility[3 * tileCount + second] and uint8(1 shl first)) != 0
      if north != southReverse or east != westReverse: return -1

  if not propagate(domains, compatibility, width, height, tileCount, 0, true): return -2
  while true:
    var bestCell = cellCount
    var bestCount = MaxTiles + 1
    for cell in 0 ..< cellCount:
      let count = popcountSmall(domains[cell])
      if count > 1 and count < bestCount:
        bestCell = cell
        bestCount = count
    if bestCell == cellCount: break
    var totalWeight = 0
    for tile in 0 ..< tileCount:
      if (domains[bestCell] and uint8(1 shl tile)) != 0: totalWeight += int(weights[tile])
    var rank = int(draws[bestCell]) * totalWeight div 65536
    var selected = tileCount
    for tile in 0 ..< tileCount:
      if (domains[bestCell] and uint8(1 shl tile)) == 0: continue
      if rank < int(weights[tile]):
        selected = tile
        break
      rank -= int(weights[tile])
    if selected == tileCount: return -2
    domains[bestCell] = uint8(1 shl selected)
    if not propagate(domains, compatibility, width, height, tileCount, bestCell, false): return -2

  var encoded = 1'i64 shl 32
  for cell in 0 ..< cellCount:
    var tile = 0
    while (domains[cell] and uint8(1 shl tile)) == 0: inc tile
    encoded = encoded or (int64(tile) shl (2 * cell))
  encoded
