proc writeRun(output: ptr UncheckedArray[uint8], positionInput: int, byte: uint8, count: int): int =
  var position = positionInput
  for _ in 0 ..< count:
    output[position] = byte
    inc position
  position

proc butterfly_pattern*(n: int64, output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "butterfly_pattern".} =
  if n < 1 or n > 45: return -1
  let side = int(n)
  let width = 2 * side - 1
  let required = width * width + 2 * side - 2
  if output == nil or capacity < csize_t(required): return -2

  var position = 0
  for count in 1 ..< side:
    if position != 0:
      output[position] = 10; inc position
    position = writeRun(output, position, uint8('*'), count)
    position = writeRun(output, position, uint8(' '), 2 * (side - count) - 1)
    position = writeRun(output, position, uint8('*'), count)
  if position != 0:
    output[position] = 10; inc position
  position = writeRun(output, position, uint8('*'), width)
  var count = side - 1
  while count > 0:
    output[position] = 10; inc position
    position = writeRun(output, position, uint8('*'), count)
    position = writeRun(output, position, uint8(' '), 2 * (side - count) - 1)
    position = writeRun(output, position, uint8('*'), count)
    dec count
  int64(position)
