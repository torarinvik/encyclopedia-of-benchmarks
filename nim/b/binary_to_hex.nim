proc binary_to_hex*(values: ptr UncheckedArray[int64], length: csize_t,
                    output: ptr UncheckedArray[uint8], output_capacity: csize_t): int64
    {.cdecl, exportc: "binary_to_hex".} =
  if length > 4096 or (length != 0 and values.isNil): return -1
  for i in 0 ..< int(length):
    if values[i] != 48 and values[i] != 49: return -1

  let output_length = (length + 3) div 4
  if output_length == 0: return 0
  if output.isNil or output_capacity < output_length: return -2

  var first_width = length mod 4
  if first_width == 0: first_width = 4
  var start = 0.csize_t
  for group in 0 ..< int(output_length):
    var width = 4.csize_t
    if group == 0: width = first_width
    var nibble = 0
    for offset in 0 ..< int(width):
      nibble = nibble * 2 + int(values[int(start) + offset] - 48)
    output[group] = uint8(if nibble < 10: 48 + nibble else: 55 + nibble)
    start += width
  int64(output_length)
