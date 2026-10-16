proc railForPosition(position, rails: int): int =
  let period = 2 * (rails - 1)
  let phase = position mod period
  if phase < rails: phase else: period - phase

proc rail_fence*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "rail_fence".} =
  if input.isNil or length < 3 or length > 260: return -1
  if input[0] < 0 or input[0] > 1 or input[1] < 2 or input[1] > 8: return -1
  if input[2] < 0 or input[2] > 256: return -1
  let mode = int(input[0])
  let rails = int(input[1])
  let n = int(input[2])
  if length != csize_t(n + 3): return -1
  for i in 0 ..< n:
    if input[i + 3] < 0 or input[i + 3] > 127: return -1
  if output.isNil or outputCapacity < csize_t(n): return -2

  if mode == 0:
    var outIndex = 0
    for rail in 0 ..< rails:
      for position in 0 ..< n:
        if railForPosition(position, rails) == rail:
          output[outIndex] = uint8(input[position + 3])
          inc outIndex
  else:
    var counts: array[8, int]
    var starts: array[8, int]
    var used: array[8, int]
    for position in 0 ..< n:
      inc counts[railForPosition(position, rails)]
    for rail in 1 ..< rails:
      starts[rail] = starts[rail - 1] + counts[rail - 1]
    for position in 0 ..< n:
      let rail = railForPosition(position, rails)
      output[position] = uint8(input[3 + starts[rail] + used[rail]])
      inc used[rail]
  int64(n)
