## Pointer-relinking selection sort modeled with bounded node indices.
const
  MaxCount = 64
  MaxInputLength = 66

proc selectionSortLinks(values: array[MaxCount, int32], next: var array[MaxCount, int], head: var int) =
  var minimum = head
  var current = next[minimum]
  var previous = minimum
  var sortedTail = -1
  while next[minimum] != -1:
    while current != -1:
      if values[current] < values[minimum]:
        if sortedTail == -1:
          if previous == minimum:
            head = current
            next[minimum] = next[current]
            next[current] = previous
            minimum = current
            current = next[previous]
          else:
            head = current
            next[previous] = next[current]
            next[current] = minimum
            minimum = current
            current = next[previous]
        else:
          next[sortedTail] = current
          next[previous] = next[current]
          next[current] = minimum
          minimum = current
          current = next[previous]
      else:
        previous = next[previous]
        current = next[current]
    sortedTail = minimum
    minimum = next[minimum]
    previous = minimum
    current = next[minimum]

proc writeI32Le(output: ptr UncheckedArray[uint8], offset: int, value: int32) =
  let bits = cast[uint32](value)
  for byte in 0 ..< 4:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 0xff'u32)

proc selectionsortlinkedlist*(input: ptr UncheckedArray[int64], length: csize_t,
                              output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "selectionsortlinkedlist".} =
  if input == nil or length < 1 or length > csize_t(MaxInputLength): return -1
  let rawCount = input[0]
  if rawCount < 1 or rawCount > int64(MaxCount) or int(length) != 1 + int(rawCount): return -1
  let count = int(rawCount)
  var values: array[MaxCount, int32]
  var next: array[MaxCount, int]
  for index in 0 ..< count:
    if input[index + 1] < int64(low(int32)) or input[index + 1] > int64(high(int32)):
      return -1
    values[index] = int32(input[index + 1])
    next[index] = if index + 1 < count: index + 1 else: -1
  let byteCount = 4 * count
  if output == nil or outputCapacity < csize_t(byteCount): return -2

  var head = 0
  selectionSortLinks(values, next, head)
  var node = head
  for index in 0 ..< count:
    writeI32Le(output, 4 * index, values[node])
    node = next[node]
  int64(byteCount)
