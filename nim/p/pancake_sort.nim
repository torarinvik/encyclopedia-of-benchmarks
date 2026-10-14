## Pancake sort using prefix reversals for the shared sorting contract.
proc flipPrefix(values: ptr UncheckedArray[int64], lastIndex: csize_t) =
  var first = csize_t(0)
  var last = lastIndex
  while first < last:
    let temporary = values[first]
    values[first] = values[last]
    values[last] = temporary
    inc first
    dec last

proc pancake_sort*(values: ptr UncheckedArray[int64], length: csize_t) {.cdecl, exportc: "pancake_sort".} =
  var prefix = length
  while prefix > 1:
    var maximum = csize_t(0)
    var probe = csize_t(1)
    while probe < prefix:
      if values[probe] > values[maximum]:
        maximum = probe
      inc probe
    if maximum != prefix - 1:
      flipPrefix(values, maximum)
      flipPrefix(values, prefix - 1)
    dec prefix
