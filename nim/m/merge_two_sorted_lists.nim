## Linear merge over two packed ascending i32 sequences.
const MaxTotalLength = 1024

proc merge_two_sorted_lists*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "merge_two_sorted_lists".} =
  if input == nil or length < 2 or length > csize_t(MaxTotalLength + 2): return -1
  if input[0] < 0 or input[0] > MaxTotalLength or input[1] < 0 or input[1] > MaxTotalLength: return -1
  let firstCount = int(input[0])
  let secondCount = int(input[1])
  if firstCount + secondCount > MaxTotalLength or int(length) != firstCount + secondCount + 2: return -1
  for index in 0 ..< firstCount:
    let value = input[index + 2]
    if value < int64(low(int32)) or value > int64(high(int32)) or
        (index > 0 and input[index + 1] > value): return -1
  let secondStart = firstCount + 2
  for index in 0 ..< secondCount:
    let value = input[secondStart + index]
    if value < int64(low(int32)) or value > int64(high(int32)) or
        (index > 0 and input[secondStart + index - 1] > value): return -1

  let totalCount = firstCount + secondCount
  let outputBytes = totalCount * 4
  if outputCapacity < csize_t(outputBytes) or (outputBytes > 0 and output == nil): return -2
  var firstIndex = 0
  var secondIndex = 0
  for written in 0 ..< totalCount:
    var value: int64
    if firstIndex == firstCount:
      value = input[secondStart + secondIndex]
      inc secondIndex
    elif secondIndex == secondCount:
      value = input[firstIndex + 2]
      inc firstIndex
    elif input[firstIndex + 2] <= input[secondStart + secondIndex]:
      value = input[firstIndex + 2]
      inc firstIndex
    else:
      value = input[secondStart + secondIndex]
      inc secondIndex
    let bits = cast[uint32](int32(value))
    for byte in 0 ..< 4:
      output[written * 4 + byte] = uint8((bits shr (byte * 8)) and 0xff'u32)
  int64(totalCount)
