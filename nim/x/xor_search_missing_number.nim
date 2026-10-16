const MaxN = 255'i64
const MaxInputLength = 257

proc xor_search_missing_number*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "xor_search_missing_number".} =
  if input.isNil or length < 1 or length > MaxInputLength: return -1
  let nValue = input[0]
  if nValue < 0 or nValue > MaxN or int(length) != int(nValue) + 1: return -1
  let n = int(nValue)
  var seen: array[256, bool]
  var result = nValue
  for i in 0 ..< n:
    let value = input[i + 1]
    if value < 0 or value > nValue or seen[int(value)]: return -1
    seen[int(value)] = true
    result = result xor int64(i) xor value
  return result
