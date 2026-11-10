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

  var invalidBits, previousDevices, beams: uint64
  var rowStart = 2
  while rowStart < int(length):
    var devices = 0'u64
    for column in 0 ..< columns:
      let cell = cast[uint64](input[rowStart + column])
      invalidBits = invalidBits or (cell xor 48)
      devices += cell and 1
    beams += devices * previousDevices
    if devices != 0: previousDevices = devices
    rowStart += columns
  if invalidBits > 1: return -1
  int64(beams)
