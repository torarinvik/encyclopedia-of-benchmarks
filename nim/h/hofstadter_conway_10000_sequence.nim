const MaxIndex = 8192'i64
const MaxParseableLength = 2

proc hofstadter_conway_10000_sequence*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "hofstadter_conway_10000_sequence".} =
  if input == nil or length < 1 or length > csize_t(MaxParseableLength): return -1
  if length != 1 or input[0] < 2 or input[0] > MaxIndex: return -1

  let target = int(input[0])
  var a: array[MaxIndex.int + 1, int64]
  a[1] = 1
  a[2] = 1
  for n in 3 .. target:
    let previous = a[n - 1]
    let other = int64(n) - previous
    if previous < 1 or previous >= int64(n) or other < 1 or other >= int64(n): return -1
    a[n] = a[int(previous)] + a[int(other)]
  a[target]
