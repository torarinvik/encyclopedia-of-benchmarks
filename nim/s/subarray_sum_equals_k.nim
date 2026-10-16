const MaxItems = 512
const TableSize = 2048
const InvalidResult = low(int64)

proc slotFor(value: int64): int =
  let magnitude = if value < 0: -value else: value
  int(magnitude mod int64(TableSize))

proc subarray_sum_equals_k*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "subarray_sum_equals_k".} =
  if input.isNil or length < 2 or length > csize_t(MaxItems + 2): return InvalidResult
  let countValue = input[0]
  let target = input[1]
  if countValue < 0 or countValue > int64(MaxItems) or target < int64(int32.low) or target > int64(int32.high):
    return InvalidResult
  let count = int(countValue)
  if length != csize_t(count + 2): return InvalidResult
  for index in 0 ..< count:
    if input[index + 2] < int64(int32.low) or input[index + 2] > int64(int32.high): return InvalidResult

  var keys: array[TableSize, int64]
  var frequencies: array[TableSize, int64]
  frequencies[0] = 1
  var prefixSum: int64 = 0
  var result: int64 = 0
  for index in 0 ..< count:
    prefixSum += input[index + 2]
    let required = prefixSum - target
    var slot = slotFor(required)
    while frequencies[slot] != 0 and keys[slot] != required: slot = (slot + 1) mod TableSize
    result += frequencies[slot]

    slot = slotFor(prefixSum)
    while frequencies[slot] != 0 and keys[slot] != prefixSum: slot = (slot + 1) mod TableSize
    if frequencies[slot] == 0: keys[slot] = prefixSum
    inc frequencies[slot]
  result
