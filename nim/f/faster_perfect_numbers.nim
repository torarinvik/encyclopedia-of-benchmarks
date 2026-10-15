const MaxInput = 2305843009213693951'i64

proc getPrimeLimit(value: int64): uint64 =
  var scaled = uint64(value) * 8'u64 + 1'u64
  var limit = 0'u64
  while scaled >= 4'u64:
    scaled = scaled div 4'u64
    inc limit
  limit

func isPrime(value: uint64): bool =
  if value < 2'u64: return false
  var divisor = 2'u64
  while divisor * divisor <= value:
    if value mod divisor == 0'u64: return false
    inc divisor
  true

func isMersennePrime(exponent: uint64): bool =
  if exponent == 2'u64: return true
  if exponent < 2'u64: return false
  let modulus = (1'u64 shl int(exponent)) - 1'u64
  var residue = 4'u64
  for _ in 0'u64 ..< exponent - 2'u64:
    residue = (residue * residue - 2'u64) mod modulus
  residue == 0'u64

proc faster_perfect_numbers*(value: int64, output: ptr UncheckedArray[uint8],
    outputCapacity: csize_t): int64 {.cdecl, exportc: "faster_perfect_numbers".} =
  if value < 0 or value > MaxInput: return -1
  var perfects: array[8, int64]
  var count = 0
  let limit = getPrimeLimit(value)
  var exponent = 2'u64
  while exponent <= limit:
    if isPrime(exponent) and isMersennePrime(exponent):
      let mersenne = (1'u64 shl int(exponent)) - 1'u64
      let perfect = mersenne * (1'u64 shl int(exponent - 1'u64))
      if perfect <= uint64(value):
        perfects[count] = int64(perfect)
        inc count
    inc exponent
  let required = csize_t(count * 8)
  if (required > 0 and output == nil) or outputCapacity < required: return -2
  for index in 0 ..< count:
    var bits = uint64(perfects[index])
    for byte in 0 ..< 8:
      output[index * 8 + byte] = uint8(bits and 255'u64)
      bits = bits shr 8
  int64(required)
