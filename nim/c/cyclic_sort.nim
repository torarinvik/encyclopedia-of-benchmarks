const MaxLength = 1024

proc cyclic_sort*(values: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "cyclic_sort".} =
  if length > MaxLength or (length > 0 and values == nil):
    return -1
  var seen: array[MaxLength + 1, bool]
  for index in 0 ..< int(length):
    let value = values[index]
    if value < 1 or value > int64(length) or seen[int(value)]:
      return -1
    seen[int(value)] = true

  var sorted: array[MaxLength, int64]
  for index in 0 ..< int(length):
    sorted[index] = values[index]
  var index = 0
  while index < int(length):
    let destination = int(sorted[index] - 1)
    if destination == index:
      inc index
    else:
      swap(sorted[index], sorted[destination])

  let outputLength = int(length) * 8
  if csize_t(outputLength) > outputCapacity or (outputLength > 0 and output == nil):
    return -2
  for item in 0 ..< int(length):
    let bits = uint64(sorted[item])
    for byte in 0 ..< 8:
      output[item * 8 + byte] = uint8((bits shr (byte * 8)) and 255)
  int64(length)
