## Counting sort for signed keys in the inclusive range [-128, 128].
proc counting_sort*(values, counts: ptr UncheckedArray[int64], length: csize_t) {.cdecl, exportc: "counting_sort".} =
  for bucket in 0 .. 256:
    counts[bucket] = 0
  for index in 0 ..< length:
    let bucket = csize_t(values[index] + 128)
    inc counts[bucket]
  var output = csize_t(0)
  for bucket in 0 .. 256:
    while counts[bucket] > 0:
      values[output] = int64(bucket) - 128
      inc output
      dec counts[bucket]
