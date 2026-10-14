## Recursively emit the canonical Tower of Hanoi move sequence.
proc emitHanoi(disks: csize_t, source, destination, auxiliary: uint8,
               output: ptr UncheckedArray[uint8], position: csize_t): csize_t =
  if disks == 0: return position
  let afterFirst = emitHanoi(disks - 1, source, auxiliary, destination, output, position)
  output[afterFirst] = source
  output[afterFirst + 1] = destination
  emitHanoi(disks - 1, auxiliary, destination, source, output, afterFirst + 2)

proc tower_of_hanoi*(values: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "tower_of_hanoi".} =
  if values == nil or length != 4 or values[0] < 0 or values[0] > 12: return -1
  for index in 1'u64 ..< 4'u64:
    if values[csize_t(index)] < 0 or values[csize_t(index)] > 2: return -1
  if values[1] == values[2] or values[1] == values[3] or values[2] == values[3]: return -1
  let disks = csize_t(values[0])
  let moveCount = (1'u64 shl int(disks)) - 1
  let required = csize_t(moveCount * 2)
  if outputCapacity < required or (required != 0 and output == nil): return -2
  discard emitHanoi(disks, uint8(values[1]), uint8(values[2]), uint8(values[3]), output, 0)
  int64(moveCount)
