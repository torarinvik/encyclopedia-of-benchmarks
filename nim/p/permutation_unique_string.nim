const MaxLength = 5
const MaxInput = 7
const MaxOutput = 601

proc permutation_unique_string*(input: ptr UncheckedArray[int64], inputLength: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc: "permutation_unique_string".} =
  if input == nil or inputLength == 0 or inputLength > csize_t(MaxInput): return -1
  if input[0] < 0 or input[0] > MaxLength or inputLength != csize_t(input[0] + 1): return -1
  let length = int(input[0])
  var current: array[MaxLength, uint8]
  for i in 0 ..< length:
    if input[i + 1] < 32 or input[i + 1] > 126: return -1
    current[i] = uint8(input[i + 1])
  for i in 1 ..< length:
    let value = current[i]
    var j = i
    while j > 0 and current[j - 1] > value:
      current[j] = current[j - 1]
      dec j
    current[j] = value
  var staged: array[MaxOutput, uint8]
  var count = 0
  while true:
    for i in 0 ..< length: staged[1 + count * length + i] = current[i]
    inc count
    if length < 2: break
    var pivot = length - 1
    while pivot > 0 and current[pivot - 1] >= current[pivot]: dec pivot
    if pivot == 0: break
    var successor = length - 1
    while current[successor] <= current[pivot - 1]: dec successor
    swap(current[pivot - 1], current[successor])
    var left = pivot
    var right = length - 1
    while left < right:
      swap(current[left], current[right])
      inc left
      dec right
  staged[0] = uint8(count)
  let outputSize = 1 + count * length
  if output == nil or capacity < csize_t(outputSize): return -2
  for i in 0 ..< outputSize: output[i] = staged[i]
  int64(outputSize)
