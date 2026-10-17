const MaxInitialValues = 64
const MaxOperations = 64
const MaxLiveValues = 128
const MaxInputLength = 258
const MaxParseableInputLength = 260
const MaxOutputBytes = 512
const MaxValue = 1_000_000'i64

proc prefix_aggregate_list*(input: ptr UncheckedArray[int64], length: csize_t,
                            output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "prefix_aggregate_list".} =
  if input.isNil or length < 3 or length > csize_t(MaxParseableInputLength): return -1
  let initialCountValue = input[0]
  if initialCountValue < 1 or initialCountValue > MaxInitialValues: return -1
  let initialCount = int(initialCountValue)
  if length < csize_t(initialCount + 2): return -1

  var prefix: array[MaxLiveValues, int64]
  for index in 0 ..< initialCount:
    let value = input[1 + index]
    if value < -MaxValue or value > MaxValue: return -1
    prefix[index] = value + (if index == 0: 0'i64 else: prefix[index - 1])

  let operationCountValue = input[1 + initialCount]
  if operationCountValue < 0 or operationCountValue > MaxOperations: return -1
  let operationCount = int(operationCountValue)
  var liveCount = initialCount
  var cursor = initialCount + 2
  var queryCount = 0
  var encoded: array[MaxOutputBytes, uint8]

  for _ in 0 ..< operationCount:
    if cursor >= int(length): return -1
    let operation = input[cursor]
    inc cursor
    if operation == 0:
      if cursor >= int(length) or liveCount >= MaxLiveValues: return -1
      let value = input[cursor]
      inc cursor
      if value < -MaxValue or value > MaxValue: return -1
      prefix[liveCount] = prefix[liveCount - 1] + value
      inc liveCount
    elif operation == 1:
      if liveCount <= 1: return -1
      dec liveCount
    elif operation == 2:
      if cursor + 1 >= int(length): return -1
      let rangeFrom = input[cursor]
      let rangeTo = input[cursor + 1]
      cursor += 2
      if rangeFrom < 1 or rangeTo < rangeFrom or rangeTo > int64(liveCount): return -1
      let fromIndex = int(rangeFrom)
      let toIndex = int(rangeTo)
      let queryResult = prefix[toIndex - 1] - (if fromIndex == 1: 0'i64 else: prefix[fromIndex - 2])
      var bits = cast[uint64](queryResult)
      for byte in 0 ..< 8:
        encoded[8 * queryCount + byte] = uint8(bits and 255'u64)
        bits = bits shr 8
      inc queryCount
    else:
      return -1

  if cursor != int(length): return -1
  let outputBytes = csize_t(8 * queryCount)
  if output.isNil or capacity < outputBytes: return -2
  for index in 0 ..< int(outputBytes):
    output[index] = encoded[index]
  int64(outputBytes)
