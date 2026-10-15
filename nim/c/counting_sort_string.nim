## Portable byte counting sort for printable non-space ASCII characters.
proc counting_sort_string*(values: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "counting_sort_string".} =
  if values.isNil or length < 1 or length > 4096: return -1
  let count = values[0]
  if count < 0 or count > 4095 or length != csize_t(count + 1): return -1

  var frequencies: array[256, int64]
  for index in 0 ..< int(count):
    let value = values[index + 1]
    if value < 33 or value > 126: return -1
    inc frequencies[int(value)]
  if output.isNil or outputCapacity < csize_t(count): return -2

  for value in 1 ..< 256: frequencies[value] += frequencies[value - 1]
  for index in countdown(int(count), 1):
    let value = int(values[index])
    dec frequencies[value]
    output[int(frequencies[value])] = uint8(value)
  count
