type
  U8Output = ptr UncheckedArray[uint8]

proc enumerate_quotients*(value: int64, output: U8Output,
    outputCapacity: csize_t): int64 {.cdecl, exportc: "enumerate_quotients".} =
  const MaxN = 100_000'i64
  if value < 1 or value > MaxN: return -1
  let n = uint64(value)
  var count = 0
  var left = 1'u64
  while left <= n:
    let quotient = n div left
    inc count
    left = n div quotient + 1
  let byteCount = (count + 1) * 8
  if output == nil or outputCapacity < csize_t(byteCount): return -2
  let countWord = uint64(count)
  for byte in 0..<8:
    output[csize_t(byte)] = uint8((countWord shr (byte * 8)) and 255'u64)
  var index = 0
  left = 1
  while left <= n:
    let quotient = n div left
    for byte in 0..<8:
      output[csize_t((index + 1) * 8 + byte)] = uint8((quotient shr (byte * 8)) and 255'u64)
    inc index
    left = n div quotient + 1
  int64(byteCount)
