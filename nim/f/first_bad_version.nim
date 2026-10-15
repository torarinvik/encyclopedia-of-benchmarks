## Find the first bad version with a lower-bound binary search.
proc first_bad_version*(version_count, first_bad: uint64): int64
    {.cdecl, exportc: "first_bad_version".} =
  if version_count == 0 or version_count > 2147483647'u64 or
      first_bad == 0 or first_bad > version_count:
    return -1

  var low = 1'u64
  var high = version_count
  while low < high:
    let middle = low + (high - low) div 2
    if middle >= first_bad:
      high = middle
    else:
      low = middle + 1
  int64(low)
