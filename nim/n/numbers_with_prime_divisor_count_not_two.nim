const MaxInputLength = 2
const MaxLimit = 1000

proc isPrimeCount(value: uint16): bool =
  if value < 2: return false
  var divisor = 2'u16
  while divisor <= value div divisor:
    if value mod divisor == 0: return false
    inc divisor
  true

proc storeI64(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 255'u64)

proc numbers_with_prime_divisor_count_not_two*(input: ptr UncheckedArray[int64],
    length: csize_t, output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "numbers_with_prime_divisor_count_not_two".} =
  if input == nil or length < 1 or length > csize_t(MaxInputLength): return -1
  if length != 1 or input[0] < 1 or input[0] > MaxLimit: return -1

  let limit = int(input[0])
  var divisorCounts: array[MaxLimit, uint16]
  for divisor in 1 ..< limit:
    var multiple = divisor
    while multiple < limit:
      inc divisorCounts[multiple]
      multiple += divisor
  var selectedCount = 0
  for n in 1 ..< limit:
    let count = divisorCounts[n]
    if count != 2 and isPrimeCount(count): inc selectedCount
  let outputBytes = selectedCount * 8
  if output == nil or capacity < csize_t(outputBytes): return -2
  var outputIndex = 0
  for n in 1 ..< limit:
    let count = divisorCounts[n]
    if count != 2 and isPrimeCount(count):
      storeI64(output, outputIndex * 8, int64(n))
      inc outputIndex
  int64(outputBytes)
