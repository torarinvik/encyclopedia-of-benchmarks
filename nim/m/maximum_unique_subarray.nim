## Maximize the sum of a contiguous window with distinct values.
proc maximum_unique_subarray*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "maximum_unique_subarray".} =
  if length > 256 or (length > 0 and values.isNil): return -1
  var keys: array[512, int64]
  var lastSeen: array[512, int]
  var occupied: array[512, bool]
  var left = 0
  var windowSum = 0'i64
  var best = 0'i64
  for index in 0 ..< int(length):
    let value = values[index]
    if value < 1 or value > 10_000: return -1
    var slot = int(value mod 512)
    while occupied[slot] and keys[slot] != value: slot = (slot + 1) mod 512
    let previous = lastSeen[slot]
    while left < previous:
      windowSum -= values[left]
      inc left
    windowSum += value
    keys[slot] = value
    lastSeen[slot] = index + 1
    occupied[slot] = true
    if windowSum > best: best = windowSum
  best
