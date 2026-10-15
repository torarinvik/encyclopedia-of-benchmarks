type
  I64Input = ptr UncheckedArray[int64]
  ByteOutput = ptr UncheckedArray[uint8]

proc hamming_numbers*(input: I64Input, length: csize_t, output: ByteOutput,
                      outputCapacity: csize_t): int64
    {.cdecl, exportc: "hamming_numbers".} =
  if input.isNil or length != 1 or input[0] < 1 or input[0] > 32: return -1
  let count = int(input[0])
  let outputBytes = count * 8
  if outputCapacity < csize_t(outputBytes) or output.isNil: return -2

  var values: array[32, uint64]
  values[0] = 1
  var i2 = 0
  var i3 = 0
  var i5 = 0
  for index in 1 ..< count:
    let c2 = values[i2] * 2
    let c3 = values[i3] * 3
    let c5 = values[i5] * 5
    var next = min(c2, c3)
    if c5 < next: next = c5
    values[index] = next
    if c2 == next: inc i2
    if c3 == next: inc i3
    if c5 == next: inc i5
  for index in 0 ..< count:
    for byte in 0 ..< 8:
      output[index * 8 + byte] = uint8((values[index] shr (byte * 8)) and 255)
  int64(count)
