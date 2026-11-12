proc storeI64(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8: output[offset + byte] = uint8((bits shr (8 * byte)) and 255)

proc maximum_frequency_stack*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc: "maximum_frequency_stack".} =
  if input == nil or length < 1 or length > 130: return -1
  let count = input[0]
  if count < 0 or count > 64 or int(length) != 1 + 2 * int(count): return -1
  var frequency: array[17, int]
  var bucketTop: array[65, int]
  for entry in 0 ..< 65: bucketTop[entry] = -1
  var nodeValue, nodeNext: array[64, int]
  var popped: array[64, int64]
  var nodes = 0
  var popCount = 0
  var position = 1
  var maximumFrequency = 0
  for _ in 0 ..< int(count):
    let opcode = input[position]
    let argument = input[position + 1]
    position += 2
    if opcode == 0:
      if argument < -8 or argument > 8: return -1
      let valueIndex = int(argument) + 8
      inc frequency[valueIndex]
      let level = frequency[valueIndex]
      nodeValue[nodes] = int(argument)
      nodeNext[nodes] = bucketTop[level]
      bucketTop[level] = nodes
      inc nodes
      if level > maximumFrequency: maximumFrequency = level
    elif opcode == 1 and argument == 0:
      if maximumFrequency == 0 or bucketTop[maximumFrequency] < 0: return -1
      let node = bucketTop[maximumFrequency]
      bucketTop[maximumFrequency] = nodeNext[node]
      let value = nodeValue[node]
      popped[popCount] = int64(value)
      inc popCount
      dec frequency[value + 8]
      if bucketTop[maximumFrequency] < 0: dec maximumFrequency
    else: return -1
  let needed = popCount * 8
  if needed > 0 and (output == nil or capacity < csize_t(needed)): return -2
  for index in 0 ..< popCount: storeI64(output, index * 8, popped[index])
  int64(needed)
