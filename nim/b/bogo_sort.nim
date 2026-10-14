## Deterministic bogo sort for the shared, bounded portable workload.
proc bogo_sort*(values: ptr UncheckedArray[int64], length: csize_t) {.cdecl, exportc: "bogo_sort".} =
  if length < 2:
    return

  var state = 2654435769'u64
  while true:
    var sorted = true
    var checkIndex = csize_t(1)
    while checkIndex < length:
      if values[checkIndex - 1] > values[checkIndex]:
        sorted = false
        break
      inc checkIndex
    if sorted:
      break

    var index = length
    while index > 1:
      dec index
      state = (state * 1664525'u64 + 1013904223'u64) mod 4294967296'u64
      let other = csize_t((state div 65536'u64) mod uint64(index + 1))
      let temporary = values[index]
      values[index] = values[other]
      values[other] = temporary
