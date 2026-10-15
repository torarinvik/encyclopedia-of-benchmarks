## Emit unique ASCII permutations after sorting and skipping duplicate choices.
const MaxLength = 6

proc generate(values: array[MaxLength, int32], n, depth: int,
    current: var array[MaxLength, int32], used: var array[MaxLength, bool],
    output: ptr UncheckedArray[uint8], resultCount: var int) =
  if depth == n:
    let row = resultCount * n
    for i in 0 ..< n: output[row + i] = uint8(current[i])
    inc resultCount
    return
  for i in 0 ..< n:
    if used[i]: continue
    if i > 0 and values[i] == values[i - 1] and not used[i - 1]: continue
    current[depth] = values[i]
    used[i] = true
    generate(values, n, depth + 1, current, used, output, resultCount)
    used[i] = false

proc unique_permutation*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "unique_permutation".} =
  if input == nil or length < 1 or length > csize_t(MaxLength + 1): return -1
  let nValue = input[0]
  if nValue < 0 or nValue > MaxLength or length != csize_t(nValue + 1): return -1
  let n = int(nValue)
  var values: array[MaxLength, int32]
  for i in 0 ..< n:
    let value = input[i + 1]
    if value < 0 or value > 127: return -1
    values[i] = int32(value)
  for i in 1 ..< n:
    let value = values[i]
    var position = i
    while position > 0 and values[position - 1] > value:
      values[position] = values[position - 1]
      dec position
    values[position] = value
  var maxCount = 1
  for factor in 2 .. n: maxCount *= factor
  let required = maxCount * n
  if outputCapacity < csize_t(required) or (required > 0 and output == nil): return -2
  var current: array[MaxLength, int32]
  var used: array[MaxLength, bool]
  var resultCount = 0
  generate(values, n, 0, current, used, output, resultCount)
  int64(resultCount)
