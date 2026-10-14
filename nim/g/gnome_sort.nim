## Stable gnome sort for the shared mutable in-place sorting contract.
proc gnome_sort*(values: ptr UncheckedArray[int64], length: csize_t) {.cdecl, exportc: "gnome_sort".} =
  if length < 2:
    return
  var position = csize_t(1)
  while position < length:
    if values[position] >= values[position - 1]:
      inc position
    else:
      let temporary = values[position - 1]
      values[position - 1] = values[position]
      values[position] = temporary
      if position > 1:
        dec position
      else:
        position = 1
