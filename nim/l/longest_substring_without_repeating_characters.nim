## Return the longest printable-ASCII substring with no repeated byte.
const MaxLength = 1024
const AlphabetSize = 95

proc longest_substring_without_repeating_characters*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "longest_substring_without_repeating_characters".} =
  if length > csize_t(MaxLength) or (length != 0 and values == nil): return -2
  var lastSeen: array[AlphabetSize, int]
  for slot in 0 ..< AlphabetSize: lastSeen[slot] = -1
  var windowStart = 0
  var longest = 0
  for index in 0 ..< int(length):
    let value = values[index]
    if value < 32 or value > 126: return -2
    let slot = int(value - 32)
    if lastSeen[slot] >= windowStart: windowStart = lastSeen[slot] + 1
    lastSeen[slot] = index
    let current = index - windowStart + 1
    if current > longest: longest = current
  int64(longest)
