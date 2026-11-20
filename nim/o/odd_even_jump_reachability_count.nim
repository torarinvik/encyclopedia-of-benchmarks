const MaxN = 64
const MaxParseable = 66

proc comesBefore(input: ptr UncheckedArray[int64], left, right: int,
                 descending: bool): bool =
  let leftValue = input[left + 1]
  let rightValue = input[right + 1]
  if leftValue != rightValue:
    return if descending: leftValue > rightValue else: leftValue < rightValue
  left < right

proc buildSuccessors(input: ptr UncheckedArray[int64], n: int,
                     descending: bool): array[MaxN, int64] =
  var order: array[MaxN, int]
  var stack: array[MaxN, int]
  for i in 0 ..< n:
    order[i] = i
    result[i] = -1
  for i in 1 ..< n:
    let key = order[i]
    var position = i
    while position > 0 and comesBefore(input, key, order[position - 1], descending):
      order[position] = order[position - 1]
      dec position
    order[position] = key
  var stackSize = 0
  for i in 0 ..< n:
    let index = order[i]
    while stackSize > 0 and stack[stackSize - 1] < index:
      dec stackSize
      result[stack[stackSize]] = int64(index)
    stack[stackSize] = index
    inc stackSize

proc odd_even_jump_reachability_count*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "odd_even_jump_reachability_count".} =
  if input.isNil or length < csize_t(2) or length > csize_t(MaxParseable): return -1
  if input[0] < 1 or input[0] > MaxN: return -1
  let n = int(input[0])
  if length != csize_t(n + 1): return -1
  for i in 0 ..< n:
    if input[i + 1] < -1_000_000 or input[i + 1] > 1_000_000: return -1

  let oddNext = buildSuccessors(input, n, false)
  let evenNext = buildSuccessors(input, n, true)
  var odd: array[MaxN, bool]
  var even: array[MaxN, bool]
  odd[n - 1] = true
  even[n - 1] = true
  var i = n - 1
  while i > 0:
    dec i
    if oddNext[i] >= 0: odd[i] = even[int(oddNext[i])]
    if evenNext[i] >= 0: even[i] = odd[int(evenNext[i])]
  var count = 0'i64
  for i in 0 ..< n:
    if odd[i]: inc count
  count
