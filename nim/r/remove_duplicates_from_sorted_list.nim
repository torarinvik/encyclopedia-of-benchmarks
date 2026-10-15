const MaxNodes = 1024

proc remove_duplicates_from_sorted_list*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "remove_duplicates_from_sorted_list".} =
  if length > csize_t(MaxNodes) or (length != 0 and input == nil): return -1
  for index in 0 ..< int(length):
    let value = input[index]
    if value < int64(low(int32)) or value > int64(high(int32)):
      return -1
    if index > 0 and input[index - 1] > value:
      return -1
  var nextNode: array[MaxNodes + 1, csize_t]
  for index in 0 ..< int(length): nextNode[index] = csize_t(index + 1)
  nextNode[int(length)] = length
  var current: csize_t = 0
  while current != length and nextNode[current] != length:
    let next = nextNode[current]
    if input[current] == input[next]: nextNode[current] = nextNode[next]
    else: current = next
  var survivorCount: csize_t = 0
  var node: csize_t = 0
  while node != length:
    inc survivorCount
    node = nextNode[node]
  let outputBytes = survivorCount * 4
  if outputCapacity < outputBytes or (outputBytes != 0 and output == nil): return -2
  var written: csize_t = 0
  node = 0
  while node != length:
    let bits = cast[uint32](int32(input[node]))
    for byte in 0 ..< 4:
      output[written * 4 + csize_t(byte)] = uint8((bits shr (byte * 8)) and 0xff'u32)
    inc written
    node = nextNode[node]
  if written != survivorCount: return -1
  int64(written)
