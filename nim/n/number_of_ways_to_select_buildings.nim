## Count alternating triples as each possible last building arrives.
const MaxLength = 4096

proc number_of_ways_to_select_buildings*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "number_of_ways_to_select_buildings".} =
  if length == 0: return 0
  if values.isNil or length > MaxLength: return -1
  var differentBits, ways: uint64
  var zeros, ones, zeroOne, oneZero: uint32
  for index in 0 ..< int(length):
    let value = cast[uint64](values[index]) xor 48
    differentBits = differentBits or value
    let isOne = (value and 1) != 0
    ways += uint64(if isOne: oneZero else: zeroOne)
    zeroOne += (if isOne: zeros else: 0'u32)
    oneZero += (if isOne: 0'u32 else: ones)
    zeros += uint32(not isOne)
    ones += uint32(isOne)
  if differentBits > 1: return -1
  int64(ways)
