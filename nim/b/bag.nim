const MaxInserts = 128
const MaxQueries = 64

proc putI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8: output[offset + byte] = uint8((bits shr (byte * 8)) and 255'u64)

proc bag*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "bag".} =
  if input.isNil or length < 2: return -1
  let insertCountValue = input[0]
  if insertCountValue < 0 or insertCountValue > MaxInserts: return -1
  let insertCount = int(insertCountValue)
  if length < csize_t(insertCount + 2): return -1
  let queryCountValue = input[insertCount + 1]
  if queryCountValue < 0 or queryCountValue > MaxQueries: return -1
  let queryCount = int(queryCountValue)
  if length != csize_t(insertCount + queryCount + 2): return -1

  for index in 0 ..< insertCount:
    if input[index + 1] < int64(low(int32)) or input[index + 1] > int64(high(int32)): return -1
  for query in 0 ..< queryCount:
    let value = input[insertCount + query + 2]
    if value < int64(low(int32)) or value > int64(high(int32)): return -1
  let outputLength = (queryCount + 2) * 8
  if output.isNil or capacity < csize_t(outputLength): return -2

  var values: array[MaxInserts, int64]
  var distinctCount = 0
  for index in 0 ..< insertCount:
    let value = input[index + 1]
    var node = 0
    while node < distinctCount and values[node] != value: inc node
    if node == distinctCount:
      values[node] = value
      inc distinctCount

  putI64Le(output, 0, insertCountValue)
  putI64Le(output, 8, if insertCount == 0: 1 else: 0)
  for query in 0 ..< queryCount:
    let target = input[insertCount + query + 2]
    var contains: int64 = 0
    for node in 0 ..< distinctCount:
      if values[node] == target: contains = 1
    putI64Le(output, (query + 2) * 8, contains)
  int64(outputLength)
