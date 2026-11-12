const MaxSourceLength = 6
const MaxInputLength = 16
const MaxOutputLength = 12

type Sequence = object
  values: array[MaxOutputLength, uint8]
  length: int

proc maximumSubsequence(input: ptr UncheckedArray[int64], base, length, requested: int): Sequence =
  var stack: array[MaxSourceLength, uint8]
  var stackLength = 0
  var deletions = length - requested
  for i in 0 ..< length:
    let digit = uint8(input[base + i])
    while deletions > 0 and stackLength > 0 and stack[stackLength - 1] < digit:
      dec stackLength
      dec deletions
    stack[stackLength] = digit
    inc stackLength
  stackLength -= deletions
  result.length = stackLength
  for i in 0 ..< stackLength: result.values[i] = stack[i]

proc compareSuffix(first: Sequence, i0: int, second: Sequence, j0: int): int =
  var i = i0
  var j = j0
  while i < first.length and j < second.length:
    if first.values[i] != second.values[j]:
      return if first.values[i] > second.values[j]: 1 else: -1
    inc i
    inc j
  if i == first.length and j == second.length: return 0
  if i == first.length: return -1
  1

proc mergeSequences(first, second: Sequence): Sequence =
  var i = 0
  var j = 0
  while i < first.length or j < second.length:
    let order = compareSuffix(first, i, second, j)
    if j == second.length or (i < first.length and order >= 0):
      result.values[result.length] = first.values[i]
      inc i
    else:
      result.values[result.length] = second.values[j]
      inc j
    inc result.length

proc greater(left, right: Sequence): bool =
  for i in 0 ..< left.length:
    if left.values[i] != right.values[i]: return left.values[i] > right.values[i]
  false

proc create_maximum_number*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "create_maximum_number".} =
  if input == nil or length < 3 or length > csize_t(MaxInputLength): return -1
  if input[0] < 0 or input[0] > MaxSourceLength or input[1] < 0 or input[1] > MaxSourceLength: return -1
  let firstLength = int(input[0])
  let secondLength = int(input[1])
  if input[2] < 0 or input[2] > firstLength + secondLength: return -1
  let requested = int(input[2])
  if length != csize_t(3 + firstLength + secondLength): return -1
  for i in 0 ..< firstLength + secondLength:
    if input[3 + i] < 0 or input[3 + i] > 9: return -1
  if output == nil or capacity < csize_t(requested): return -2

  let minimumFirst = max(0, requested - secondLength)
  let maximumFirst = min(requested, firstLength)
  var best: Sequence
  var haveBest = false
  for takeFirst in minimumFirst .. maximumFirst:
    let first = maximumSubsequence(input, 3, firstLength, takeFirst)
    let second = maximumSubsequence(input, 3 + firstLength, secondLength, requested - takeFirst)
    let candidate = mergeSequences(first, second)
    if not haveBest or greater(candidate, best):
      best = candidate
      haveBest = true
  for i in 0 ..< requested: output[i] = best.values[i]
  int64(requested)
