proc lipogram*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "lipogram".} =
  if input.isNil or length < 2 or length > 1026 or input[0] < 0 or input[0] > 1024 or length != csize_t(input[0] + 2): return -1
  let n = int(input[0])
  let expected = input[length - 1]
  if expected < 0 or expected > 67108863: return -1
  var seen: array[26, bool]
  for i in 0 ..< n:
    var ch = input[i + 1]
    if ch >= 65 and ch <= 90: ch += 32
    if ch >= 97 and ch <= 122:
      seen[int(ch - 97)] = true
    elif ch != 9 and ch != 10 and ch != 11 and ch != 12 and ch != 13 and ch != 32:
      return -1
  var missing = 0'i64
  var bit = 1'i64
  for i in 0 ..< 26:
    if not seen[i]: missing += bit
    bit *= 2
  if missing == expected: 1 else: 0
