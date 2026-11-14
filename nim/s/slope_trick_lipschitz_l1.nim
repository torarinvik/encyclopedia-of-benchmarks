## Uncompiled and unexecuted two-heap slope-trick draft.
proc push(heap: var array[128, int64], count: var int, value: int64) =
  var i = count
  inc count
  while i > 0:
    let parent = (i-1) div 2
    if heap[parent] >= value: break
    heap[i] = heap[parent]
    i = parent
  heap[i] = value

proc replace(heap: var array[128, int64], count: int, value: int64) =
  var i = 0
  while 2*i+1 < count:
    var child = 2*i+1
    if child+1 < count and heap[child+1] > heap[child]: inc child
    if heap[child] <= value: break
    heap[i] = heap[child]
    i = child
  heap[i] = value

proc slope_trick_lipschitz_l1*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "slope_trick_lipschitz_l1".} =
  if input.isNil or length < 2 or length > 130: return -1
  if input[0] < 0 or input[0] > 128 or input[1] < 0 or input[1] > 100: return -1
  let n = int(input[0])
  if length != csize_t(n+2): return -1
  for i in 0 ..< n:
    if input[2+i] < 0 or input[2+i] > 100: return -1
  var left, right: array[128, int64]
  var ln, rn = 0
  var shiftL, shiftR, answer = 0'i64
  for i in 0 ..< n:
    shiftL -= input[1]
    shiftR += input[1]
    push(left, ln, input[2+i]-shiftL)
    push(right, rn, shiftR-input[2+i])
    let l = left[0]+shiftL
    let r = shiftR-right[0]
    if l > r:
      answer += l-r
      replace(left, ln, r-shiftL)
      replace(right, rn, shiftR-l)
  answer
