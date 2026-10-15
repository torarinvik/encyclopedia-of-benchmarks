## Check whether every present value has a distinct occurrence count.
proc unique_occurrences*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "unique_occurrences".} =
  if length > 1000 or (length > 0 and values.isNil): return -1
  var counts: array[2001, int64]
  var seenFrequencies: array[1001, bool]
  for index in 0 ..< int(length):
    let value = values[index]
    if value < -1000 or value > 1000: return -1
    inc counts[int(value + 1000)]
  for frequency in counts:
    if frequency == 0: continue
    if seenFrequencies[int(frequency)]: return 0
    seenFrequencies[int(frequency)] = true
  1
