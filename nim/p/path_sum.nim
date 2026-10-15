## Check whether a root-to-leaf path has the requested sum.
const MaxNodes = 63

proc pathHasSum(input: ptr UncheckedArray[int64], node: int, sum, target: int64): bool =
  let base = 2 + 3 * node
  let nextSum = sum + input[base]
  let left = input[base + 1]
  let right = input[base + 2]
  if left == -1 and right == -1: return nextSum == target
  (left != -1 and pathHasSum(input, int(left), nextSum, target)) or
    (right != -1 and pathHasSum(input, int(right), nextSum, target))

proc path_sum*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "path_sum".} =
  if length < 2 or input[1] < 0 or input[1] > MaxNodes: return -1
  let count = int(input[1])
  if length != csize_t(2 + 3 * count): return -1
  if count == 0: return 0
  for index in 0 ..< count:
    let base = 2 + 3 * index
    if input[base] < -2147483648 or input[base] > 2147483647: return -1
    for edge in 1 .. 2:
      if input[base + edge] < -1 or input[base + edge] >= count: return -1
  var seen: array[MaxNodes, bool]
  var stack: array[MaxNodes, int]
  var top = 1
  var visited = 0
  stack[0] = 0
  while top > 0:
    dec top
    let node = stack[top]
    if seen[node]: return -1
    seen[node] = true
    inc visited
    let base = 2 + 3 * node
    let left = input[base + 1]
    let right = input[base + 2]
    if left != -1:
      stack[top] = int(left)
      inc top
    if right != -1:
      stack[top] = int(right)
      inc top
  if visited != count: return -1
  if pathHasSum(input, 0, 0, input[0]): 1 else: 0
