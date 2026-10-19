const MaxLimit = 1_000_000'i64
const MaxWords = 15626

proc countPrimes(limit: int64): int64 =
  var bits: array[MaxWords, uint64]
  for word in 0 ..< MaxWords: bits[word] = high(uint64)
  var count = 0'i64
  var value = 2'i64
  while value <= limit:
    let word = int(value shr 6)
    let mask = 1'u64 shl int(value and 63)
    if (bits[word] and mask) != 0:
      inc count
      var multiple = value + value
      while multiple <= limit:
        let multipleWord = int(multiple shr 6)
        let multipleMask = 1'u64 shl int(multiple and 63)
        if (bits[multipleWord] and multipleMask) != 0: bits[multipleWord] = bits[multipleWord] xor multipleMask
        multiple += value
    inc value
  count

proc putU64Le(output: ptr UncheckedArray[uint8], offset: int, value: uint64) =
  for byte in 0 ..< 8: output[offset + byte] = uint8((value shr (8 * byte)) and 0xFF'u64)

proc benchmarkgame_nsieve_bits*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "benchmarkgame_nsieve_bits".} =
  if input.isNil or length != 1 or input[0] < 0 or input[0] > MaxLimit: return -1
  if output.isNil or capacity < 24: return -2
  for pass in 0 ..< 3: putU64Le(output, pass * 8, uint64(countPrimes(input[0] shr pass)))
  24
