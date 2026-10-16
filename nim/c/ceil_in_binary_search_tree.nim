const MaxNodeCount = 127
const MaxInputLength = 3 + 3 * MaxNodeCount
const ValueMin = -1_000_000'i64
const ValueMax = 1_000_000'i64
const InvalidResult = low(int64) + 1
const NoCeilResult = low(int64)

## Return the least tree value greater than or equal to the query.
proc ceil_in_binary_search_tree*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "ceil_in_binary_search_tree".} =
  if input.isNil or length < 3 or length > MaxInputLength: return InvalidResult
  let nodeCountValue = input[0]
  let rootIndexValue = input[1]
  let key = input[2]
  if nodeCountValue < 0 or nodeCountValue > MaxNodeCount or key < ValueMin or key > ValueMax: return InvalidResult
  let nodeCount = int(nodeCountValue)
  if int(length) != 3 + 3 * nodeCount: return InvalidResult
  if nodeCount == 0:
    return if rootIndexValue == -1: NoCeilResult else: InvalidResult
  if rootIndexValue < 0 or rootIndexValue >= nodeCountValue: return InvalidResult

  var current = int(rootIndexValue)
  var best = NoCeilResult
  var steps = 0
  while current >= 0:
    if steps >= nodeCount: return InvalidResult
    let offset = 3 + 3 * current
    let value = input[offset]
    let left = input[offset + 1]
    let right = input[offset + 2]
    if value < ValueMin or value > ValueMax or left < -1 or right < -1 or left >= nodeCountValue or right >= nodeCountValue:
      return InvalidResult
    if value == key: return value
    if value < key:
      current = int(right)
    else:
      best = value
      current = int(left)
    inc steps
  best
