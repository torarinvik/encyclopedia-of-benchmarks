proc tsvc_s331_last_negative_index*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "tsvc_s331_last_negative_index".} =
  if input.isNil or length < 2 or length > 257: return -1
  let n = input[0]
  if n < 1 or n > 256 or length != csize_t(1 + n): return -1
  var result = 0'i64
  for i in 0 ..< int(n):
    let value = input[1 + i]
    if value < -1_000_000 or value > 1_000_000: return -1
    if value < 0: result = int64(i + 1)
  result
