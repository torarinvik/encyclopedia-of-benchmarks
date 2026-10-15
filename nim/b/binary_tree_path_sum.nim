const MaxNodes = 63

proc countFrom(input: ptr UncheckedArray[int64], node: int, sum, target: int64): int64 =
  let base = 2 + 3 * node
  var count = if sum == target: 1'i64 else: 0'i64
  let left = input[base + 1]
  let right = input[base + 2]
  if left >= 0: count += countFrom(input, int(left), sum + input[2 + 3 * int(left)], target)
  if right >= 0: count += countFrom(input, int(right), sum + input[2 + 3 * int(right)], target)
  count

proc startAtEachNode(input: ptr UncheckedArray[int64], node: int): int64 =
  let base = 2 + 3 * node
  var count = countFrom(input, node, input[base], input[0])
  let left = input[base + 1]
  let right = input[base + 2]
  if left >= 0: count += startAtEachNode(input, int(left))
  if right >= 0: count += startAtEachNode(input, int(right))
  count

proc binary_tree_path_sum*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "binary_tree_path_sum".} =
  if input.isNil or length < 2 or input[1] < 0 or input[1] > MaxNodes: return -1
  let count = int(input[1])
  if int(length) != 2 + 3 * count: return -1
  if count == 0: return 0
  var parents: array[MaxNodes, int]
  for node in 0 ..< count:
    let base = 2 + 3 * node
    if input[base] < int64(low(int32)) or input[base] > int64(high(int32)): return -1
    for side in 1 .. 2:
      let child = input[base + side]
      if child < -1 or child >= int64(count): return -1
      if child >= 0:
        inc parents[int(child)]
        if parents[int(child)] > 1: return -1
  if parents[0] != 0: return -1
  for node in 1 ..< count:
    if parents[node] != 1: return -1
  var seen: array[MaxNodes, bool]
  var stack: array[MaxNodes, int]
  var top = 0
  var reached = 0
  stack[top] = 0; inc top
  while top > 0:
    dec top
    let node = stack[top]
    if seen[node]: return -1
    seen[node] = true; inc reached
    let base = 2 + 3 * node
    if input[base + 1] >= 0: stack[top] = int(input[base + 1]); inc top
    if input[base + 2] >= 0: stack[top] = int(input[base + 2]); inc top
  if reached != count: return -1
  startAtEachNode(input, 0)
