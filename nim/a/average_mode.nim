## Return the unique mode of a bounded integer sequence.
proc average_mode*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "average_mode".} =
  if values == nil or length == 0 or length > 64: return -1
  for i in 0 ..< int(length):
    if values[i] < 0 or values[i] > 1000: return -1

  var mode = -1'i64
  var maximumCount = 0
  var tied = false
  for i in 0 ..< int(length):
    var seen = false
    for before in 0 ..< i:
      if values[before] == values[i]:
        seen = true
        break
    if seen: continue

    var count = 0
    for j in 0 ..< int(length):
      if values[j] == values[i]: inc count
    if count > maximumCount:
      maximumCount = count
      mode = values[i]
      tied = false
    elif count == maximumCount:
      tied = true
  if tied: return -1
  mode
