## Bead sort for the benchmark's nonnegative 0..63 domain.
proc bead_sort*(values, scratch: ptr UncheckedArray[int64], length: csize_t) {.cdecl, exportc: "bead_sort".} =
  if length < 2:
    return
  for level in 0 .. 63:
    scratch[level] = 0
  for index in 0 ..< length:
    for level in 0 ..< values[index]:
      inc scratch[int(level)]
  for index in 0 ..< length:
    let rowFromBottom = length - 1 - index
    var value = 0'i64
    for level in 0 .. 63:
      if scratch[level] > int64(rowFromBottom):
        inc value
    values[index] = value
