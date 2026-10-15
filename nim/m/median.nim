## Return twice the statistical median using a local insertion-sorted copy.
const MaxValues = 1024

proc median*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "median".} =
  if length == 0 or length > MaxValues: return 0
  var ordered: array[MaxValues, int64]
  let n = int(length)
  for index in 0 ..< n: ordered[index] = values[index]
  for index in 1 ..< n:
    let value = ordered[index]
    var cursor = index
    while cursor > 0 and ordered[cursor - 1] > value:
      ordered[cursor] = ordered[cursor - 1]
      dec cursor
    ordered[cursor] = value
  if n mod 2 != 0: return ordered[n div 2] * 2
  ordered[n div 2 - 1] + ordered[n div 2]
