## Uncompiled and unexecuted Cartesian-tree histogram draft.
proc cartesian_histogram_area*(heights: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "cartesian_histogram_area".} =
  if length == 0: return 0
  if heights.isNil or length > 64: return low(int64)
  let n = int(length)
  for i in 0 ..< n:
    if heights[i] < 0 or heights[i] > 1000000: return low(int64)
  var left, right, stack, order, sizes: array[64, int]
  for i in 0 ..< n:
    left[i] = n
    right[i] = n
  var top = 0
  for i in 0 ..< n:
    var last = n
    while top > 0 and heights[stack[top-1]] > heights[i]:
      dec top
      last = stack[top]
    if top > 0: right[stack[top-1]] = i
    left[i] = last
    stack[top] = i
    inc top
  let root = stack[0]
  top = 1
  stack[0] = root
  var used = 0
  while top > 0:
    dec top
    let node = stack[top]
    order[used] = node
    inc used
    if left[node] < n:
      stack[top] = left[node]
      inc top
    if right[node] < n:
      stack[top] = right[node]
      inc top
  var best = 0'i64
  while used > 0:
    dec used
    let node = order[used]
    sizes[node] = 1
    if left[node] < n: sizes[node] += sizes[left[node]]
    if right[node] < n: sizes[node] += sizes[right[node]]
    best = max(best, heights[node]*int64(sizes[node]))
  best
