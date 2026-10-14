## Stable strand sort using caller-provided temporary storage.
proc strand_sort*(values, scratch: ptr UncheckedArray[int64], length: csize_t) {.cdecl, exportc: "strand_sort".} =
  if length < 2:
    return
  var remaining = length
  var resultLength = csize_t(0)
  while remaining > 0:
    var strandLength = csize_t(0)
    var remainingWrite = csize_t(0)
    for read in 0 ..< remaining:
      let value = values[read]
      if strandLength == 0 or value >= scratch[strandLength - 1]:
        scratch[strandLength] = value
        inc strandLength
      else:
        values[remainingWrite] = value
        inc remainingWrite
    let oldStart = length - resultLength
    let newStart = oldStart - strandLength
    for index in 0 ..< resultLength:
      values[newStart + index] = values[oldStart + index]
    var left = resultLength
    var right = strandLength
    var destination = length
    while left > 0 and right > 0:
      if values[newStart + left - 1] > scratch[right - 1]:
        dec left
        dec destination
        values[destination] = values[newStart + left]
      else:
        dec right
        dec destination
        values[destination] = scratch[right]
    while right > 0:
      dec right
      dec destination
      values[destination] = scratch[right]
    remaining = remainingWrite
    resultLength += strandLength
