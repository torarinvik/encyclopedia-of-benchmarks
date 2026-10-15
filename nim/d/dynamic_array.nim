const MaxOperations = 128
const MaxElements = 64
const MaxInputLength = 1 + 3 * MaxOperations

proc writeI64Le(output: ptr UncheckedArray[uint8], wordIndex: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[wordIndex * 8 + byte] = uint8((bits shr (byte * 8)) and 255)

proc dynamic_array*(input: ptr UncheckedArray[int64], length: csize_t,
                    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "dynamic_array".} =
  if input.isNil or length < 1 or length > csize_t(MaxInputLength): return -1
  let operationCountValue = input[0]
  if operationCountValue < 0 or operationCountValue > MaxOperations: return -1

  var first: array[MaxElements, int64]
  var second: array[MaxElements, int64]
  var queryResults: array[MaxOperations, int64]
  var activeFirst = true
  var size = 0
  var capacity = 16
  var cursor = 1
  var queryCount = 0
  let inputLength = int(length)

  for operationIndex in 0 ..< int(operationCountValue):
    if cursor >= inputLength: return -1
    let operation = input[cursor]
    inc cursor
    if operation == 0:
      if cursor >= inputLength or size >= MaxElements: return -1
      let value = input[cursor]
      inc cursor
      if size == capacity:
        if activeFirst:
          for index in 0 ..< size: second[index] = first[index]
          activeFirst = false
        else:
          for index in 0 ..< size: first[index] = second[index]
          activeFirst = true
        capacity *= 2
      if activeFirst: first[size] = value
      else: second[size] = value
      inc size
    elif operation == 1:
      if cursor + 1 >= inputLength: return -1
      let indexValue = input[cursor]
      let value = input[cursor + 1]
      cursor += 2
      if indexValue < 0 or indexValue >= int64(size): return -1
      let index = int(indexValue)
      if activeFirst: first[index] = value
      else: second[index] = value
    elif operation == 2:
      if cursor >= inputLength or queryCount >= MaxOperations: return -1
      let indexValue = input[cursor]
      inc cursor
      if indexValue < 0 or indexValue >= int64(size): return -1
      let index = int(indexValue)
      if activeFirst: queryResults[queryCount] = first[index]
      else: queryResults[queryCount] = second[index]
      inc queryCount
    elif operation == 3:
      if queryCount >= MaxOperations: return -1
      queryResults[queryCount] = int64(size)
      inc queryCount
    else:
      return -1
  if cursor != inputLength: return -1

  let outputWords = 2 + queryCount + size
  let outputBytes = outputWords * 8
  if output.isNil or outputCapacity < csize_t(outputBytes): return -2
  writeI64Le(output, 0, int64(queryCount))
  for index in 0 ..< queryCount: writeI64Le(output, index + 1, queryResults[index])
  writeI64Le(output, queryCount + 1, int64(size))
  for index in 0 ..< size:
    let value = if activeFirst: first[index] else: second[index]
    writeI64Le(output, queryCount + 2 + index, value)
  int64(outputWords)
