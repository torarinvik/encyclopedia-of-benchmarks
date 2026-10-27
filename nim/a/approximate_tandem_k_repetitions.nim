const MaxText = 24
const MaxInput = 26
const MaxOutput = 34504

proc mismatchCount(input: ptr UncheckedArray[int64], start, factorLength, period: int): int =
  for offset in 0 ..< factorLength - period:
    if input[2 + start + offset] != input[2 + start + offset + period]: inc result

proc recordCount(input: ptr UncheckedArray[int64], n, budget: int): int =
  for start in 0 ..< n:
    let remaining = n - start
    for period in 1 .. (remaining - 1) div 2:
      for factorLength in (2 * period + 1) .. remaining:
        if mismatchCount(input, start, factorLength, period) <= budget: inc result

proc storeI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8: output[offset + byte] = uint8((bits shr (8 * byte)) and 255'u64)

proc approximate_tandem_k_repetitions*(input: ptr UncheckedArray[int64], length: csize_t,
                                       output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "approximate_tandem_k_repetitions".} =
  if input.isNil or length < 5 or length > MaxInput: return -1
  let n0 = input[0]
  let budget0 = input[1]
  if n0 < 3 or n0 > MaxText or budget0 < 0 or budget0 > 8 or int(length) != int(n0) + 2: return -1
  let n = int(n0)
  let budget = int(budget0)
  for i in 0 ..< n:
    if input[2 + i] < 0 or input[2 + i] > 3: return -1
  let count = recordCount(input, n, budget)
  let bytes = 8 * (1 + 4 * count)
  if bytes > MaxOutput: return -1
  if output.isNil or int(capacity) < bytes: return -2
  storeI64Le(output, 0, int64(count))
  var record = 0
  for start in 0 ..< n:
    let remaining = n - start
    for period in 1 .. (remaining - 1) div 2:
      for factorLength in (2 * period + 1) .. remaining:
        let errors = mismatchCount(input, start, factorLength, period)
        if errors <= budget:
          let offset = 8 * (1 + 4 * record)
          storeI64Le(output, offset, int64(start))
          storeI64Le(output, offset + 8, int64(factorLength))
          storeI64Le(output, offset + 16, int64(period))
          storeI64Le(output, offset + 24, int64(errors))
          inc record
  int64(bytes)
