const
  MaxSetSize = 64
  MaxResultSize = 2 * MaxSetSize
  MaxInputLength = 4 + 2 * MaxSetSize

type
  I64Input = ptr UncheckedArray[int64]
  U8Output = ptr UncheckedArray[uint8]
  FixedSet = array[MaxSetSize, int64]
  FixedResult = array[MaxResultSize, int64]

proc contains(values: FixedSet, count: int, target: int64): bool =
  for i in 0..<count:
    if values[i] == target: return true
  false

proc isSubset(left: FixedSet, leftCount: int, right: FixedSet, rightCount: int): bool =
  if leftCount > rightCount: return false
  for i in 0..<leftCount:
    if not contains(right, rightCount, left[i]): return false
  true

proc putI64Le(output: U8Output, offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0..<8: output[offset + byte] = uint8((bits shr (8 * byte)) and 0xFF'u64)

proc set_algebra*(input: I64Input, length: csize_t, output: U8Output,
    capacity: csize_t): int64 {.cdecl, exportc: "set_algebra".} =
  if input.isNil or length < 4 or length > csize_t(MaxInputLength): return -1
  let operation = input[0]
  let leftRaw = input[1]
  let rightRaw = input[2]
  let queryKey = input[3]
  if operation < 0 or operation > 8 or leftRaw < 0 or leftRaw > int64(MaxSetSize) or rightRaw < 0 or rightRaw > int64(MaxSetSize) or queryKey < -1_000_000'i64 or queryKey > 1_000_000'i64: return -1
  let leftLength = int(leftRaw)
  let rightLength = int(rightRaw)
  if length != csize_t(4 + leftLength + rightLength): return -1

  var left: FixedSet
  var right: FixedSet
  var result: FixedResult
  var leftCount = 0
  var rightCount = 0
  var resultCount = 0
  for i in 0..<leftLength:
    let value = input[4 + i]
    if value < -1_000_000'i64 or value > 1_000_000'i64: return -1
    if not contains(left, leftCount, value):
      left[leftCount] = value
      inc leftCount
  for i in 0..<rightLength:
    let value = input[4 + leftLength + i]
    if value < -1_000_000'i64 or value > 1_000_000'i64: return -1
    if not contains(right, rightCount, value):
      right[rightCount] = value
      inc rightCount

  if operation == 0: result[0] = (if contains(left, leftCount, queryKey): 1'i64 else: 0'i64); resultCount = 1
  elif operation == 1: result[0] = (if isSubset(left, leftCount, right, rightCount): 1'i64 else: 0'i64); resultCount = 1
  elif operation == 2: result[0] = (if leftCount < rightCount and isSubset(left, leftCount, right, rightCount): 1'i64 else: 0'i64); resultCount = 1
  elif operation == 3: result[0] = (if isSubset(right, rightCount, left, leftCount): 1'i64 else: 0'i64); resultCount = 1
  elif operation == 4: result[0] = (if rightCount < leftCount and isSubset(right, rightCount, left, leftCount): 1'i64 else: 0'i64); resultCount = 1
  elif operation == 5:
    for i in 0..<leftCount: result[resultCount] = left[i]; inc resultCount
    for i in 0..<rightCount:
      if not contains(left, leftCount, right[i]): result[resultCount] = right[i]; inc resultCount
  elif operation == 6:
    for i in 0..<leftCount:
      if contains(right, rightCount, left[i]): result[resultCount] = left[i]; inc resultCount
  elif operation == 7:
    for i in 0..<leftCount:
      if not contains(right, rightCount, left[i]): result[resultCount] = left[i]; inc resultCount
  else:
    for i in 0..<leftCount:
      if not contains(right, rightCount, left[i]): result[resultCount] = left[i]; inc resultCount
    for i in 0..<rightCount:
      if not contains(left, leftCount, right[i]): result[resultCount] = right[i]; inc resultCount
  for i in 1..<resultCount:
    let value = result[i]
    var j = i
    while j > 0 and result[j - 1] > value:
      result[j] = result[j - 1]
      dec j
    result[j] = value

  let outputBytes = resultCount * 8
  if capacity < csize_t(outputBytes) or (outputBytes > 0 and output.isNil): return -2
  for i in 0..<resultCount: putI64Le(output, i * 8, result[i])
  int64(outputBytes)
