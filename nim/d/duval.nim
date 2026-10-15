## Least cyclic shift index using Duval's linear-time scan.
proc duval*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "duval".} =
  if length > 4096: return -1
  if length == 0: return 0
  if values.isNil: return -1
  for index in 0 ..< length:
    if values[index] < 0 or values[index] > 127: return -1

  var i: csize_t = 0
  var answer: csize_t = 0
  while i < length:
    answer = i
    var j = i + 1
    var k = i
    while j < 2 * length and values[j mod length] >= values[k mod length]:
      if values[k mod length] < values[j mod length]: k = i
      else: k += 1
      j += 1
    while i <= k: i += j - k
  int64(answer)
