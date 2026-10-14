## First-match linear search for the shared benchmark contract.
## This entry point uses C's pointer, size_t, and fixed-width integer ABI.
proc linear_search*(values: ptr UncheckedArray[int64], length: csize_t, target: int64): int64 {.cdecl, exportc: "linear_search".} =
  var index: csize_t = 0
  while index < length:
    if values[index] == target:
      return int64(index)
    inc index

  return -1
