## Count adjacent nonempty-row device pairs in a fixed-width binary bank.
const MaxDimension = 64
const MaxCells = MaxDimension * MaxDimension

proc number_of_laser_beams*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "number_of_laser_beams".} =
  if input == nil or length < 2 or length > MaxCells + 2: return -1
  if input[0] < 1 or input[0] > MaxDimension or input[1] < 1 or input[1] > MaxDimension: return -1
  let rows = int(input[0])
  let columns = int(input[1])
  if int(length) != rows * columns + 2: return -1

  var previousDevices = 0'i64
  var beams = 0'i64
  for row in 0 ..< rows:
    var devices = 0'i64
    for column in 0 ..< columns:
      let cell = input[2 + row * columns + column]
      if cell != 48 and cell != 49: return -1
      if cell == 49: inc devices
    if devices != 0:
      beams += devices * previousDevices
      previousDevices = devices
  beams
