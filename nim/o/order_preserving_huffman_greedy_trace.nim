const MaxInput = 10

proc putI64(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for b in 0..<8: output[offset + b] = uint8((bits shr (8 * b)) and 255)

proc order_preserving_huffman_greedy_trace*(input: ptr UncheckedArray[int64], inputLength: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "order_preserving_huffman_greedy_trace".} =
  if input == nil or inputLength < 3 or inputLength > MaxInput.csize_t: return -1
  let nValue = input[0]
  if nValue < 2 or nValue > 8 or inputLength != (nValue + 1).csize_t: return -1
  let n = int(nValue)
  var weights: array[15, int64]
  var left, right: array[15, int]
  var active: array[8, int]
  for i in 0..<15: left[i] = -1; right[i] = -1
  var total = 0'i64
  for i in 0..<n:
    let w = input[i + 1]
    if w < 1 or w > 15: return -1
    weights[i] = w; total += w; active[i] = i
  if total > 120: return -1
  var count = n
  var nextNode = n
  while count > 1:
    var pair = 0
    var best = weights[active[0]] + weights[active[1]]
    for i in 1..<count - 1:
      let candidate = weights[active[i]] + weights[active[i + 1]]
      if candidate < best: pair = i; best = candidate
    let a = active[pair]
    let b = active[pair + 1]
    weights[nextNode] = best; left[nextNode] = a; right[nextNode] = b
    for i in pair..<count - 2: active[i] = active[i + 2]
    count -= 2
    for i in countdown(count, pair + 1): active[i] = active[i - 1]
    active[pair] = nextNode
    count += 1; nextNode += 1
  var depths: array[8, int64]
  var nodeStack, depthStack: array[16, int]
  var top = 1
  nodeStack[0] = active[0]
  depthStack[0] = 0
  while top > 0:
    dec top
    let node = nodeStack[top]
    let depth = depthStack[top]
    if node < n: depths[node] = int64(depth)
    else:
      nodeStack[top] = left[node]; depthStack[top] = depth + 1; inc top
      nodeStack[top] = right[node]; depthStack[top] = depth + 1; inc top
  var words: array[10, int64]
  words[0] = nValue
  for i in 0..<n: words[1] += input[i + 1] * depths[i]; words[i + 2] = depths[i]
  let needed = 8 * (n + 2)
  var staged: array[80, uint8]
  for i in 0..<n + 2: putI64(cast[ptr UncheckedArray[uint8]](addr staged[0]), 8 * i, words[i])
  if output == nil or outputCapacity < needed.csize_t: return -2
  for i in 0..<needed: output[i] = staged[i]
  int64(needed)
