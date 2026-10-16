proc writeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  var bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8(bits and 255'u64)
    bits = bits shr 8

proc isFilled(rowStart, colStart: int): bool =
  var row = rowStart
  var col = colStart
  while row != 0 or col != 0:
    if row mod 3 == 1 and col mod 3 == 1: return false
    row = row div 3
    col = col div 3
  true

proc sierpinski_carpet*(input: ptr UncheckedArray[int64], length: csize_t,
                        output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "sierpinski_carpet".} =
  if input == nil or length != 3: return -1
  let depth = input[0]
  let filled = input[1]
  let hole = input[2]
  if depth < 0 or depth > 4 or filled < 32 or filled > 126 or
      hole < 32 or hole > 126 or filled == hole: return -1
  var side = 1
  for _ in 0 ..< int(depth): side *= 3
  let needed = 8 + side * side + side - 1
  if output == nil or capacity < csize_t(needed): return -2

  writeI64Le(output, 0, int64(side))
  var out = 8
  for row in 0 ..< side:
    for col in 0 ..< side:
      output[out] = if isFilled(row, col): uint8(filled) else: uint8(hole)
      inc out
    if row + 1 < side:
      output[out] = 10'u8
      inc out
  int64(needed)
