## Emit fixed-size index combinations as little-endian subset masks.
proc subset_combinations*(input: ptr UncheckedArray[int64], length: csize_t,
                          output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "subset_combinations".} =
  if length == 0 or length > 13 or input[0] < 0: return -1
  let itemCount = int(length - 1)
  if itemCount > 12: return -1
  if input[0] > int64(itemCount): return 0
  let choose = int(input[0])
  var count = 1
  for index in 1 .. choose: count = count * (itemCount - choose + index) div index
  let required = 2 * count
  if outputCapacity < csize_t(required) or (required > 0 and output.isNil): return -2

  var indices: array[12, int]
  for index in 0 ..< choose: indices[index] = index
  for combination in 0 ..< count:
    var mask = 0
    for index in 0 ..< choose: mask = mask or (1 shl indices[index])
    output[2 * combination] = uint8(mask mod 256)
    output[2 * combination + 1] = uint8(mask div 256)
    if combination + 1 == count: break
    var position = choose
    while position > 0:
      dec position
      if indices[position] < itemCount - choose + position: break
    inc indices[position]
    for index in position + 1 ..< choose: indices[index] = indices[index - 1] + 1
  int64(count)
