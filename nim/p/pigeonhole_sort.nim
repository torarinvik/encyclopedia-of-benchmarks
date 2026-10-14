## Portable pigeonhole sort for signed keys in [-128, 128].
proc pigeonhole_sort*(values, scratch: ptr UncheckedArray[int64], length: csize_t) {.cdecl, exportc: "pigeonhole_sort".} =
  if length < 2:
    return
  for bucket in 0 .. 256:
    scratch[bucket] = 0
  for index in 0 ..< length:
    let bucket = int(values[index] + 128)
    inc scratch[bucket]
  var index = csize_t(0)
  for bucket in 0 .. 256:
    while scratch[bucket] > 0:
      values[index] = int64(bucket) - 128
      inc index
      dec scratch[bucket]
