const MaxN = 31
const MaxOutput = 256
const Inf = int64.high div 4

proc put(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0..<8: output[offset + byte] = uint8((bits shr (8 * byte)) and 255)

proc technology_mapping_minimum_area_tree_cover*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc: "technology_mapping_minimum_area_tree_cover".} =
  if input.isNil or length < 9 or length > 99 or input[0] < 1 or input[0] > MaxN: return -1
  let n = int(input[0])
  if int(length) != 6 + 3 * n: return -1
  var costs: array[5, int64]
  for p in 0..<5:
    costs[p] = input[1 + p]
    if costs[p] != -1 and (costs[p] < 1 or costs[p] > 1_000_000): return -1
  var kind: array[MaxN, int]
  var left, right, parents: array[MaxN, int]
  for i in 0..<n:
    let at = 6 + 3 * i
    let k, l, r = input[at], input[at + 1], input[at + 2]
    if k < 0 or k > 2: return -1
    kind[i] = int(k); left[i] = int(l); right[i] = int(r)
    if k == 0:
      if l != -1 or r != -1: return -1
    elif k == 1:
      if l <= int64(i) or l >= int64(n) or r != -1: return -1
      inc parents[int(l)]
    else:
      if l <= int64(i) or l >= int64(n) or r <= int64(i) or r >= int64(n) or l == r: return -1
      inc parents[int(l)]; inc parents[int(r)]
  if parents[0] != 0: return -1
  for i in 1..<n: if parents[i] != 1: return -1
  var best: array[MaxN, int64]
  var choice: array[MaxN, int]
  for i in 0..<MaxN: best[i] = Inf; choice[i] = -1
  for rev in 0..<n:
    let i = n - 1 - rev
    if kind[i] == 0: best[i] = 0; continue
    let l, r = left[i], right[i]
    var candidate: int64
    if kind[i] == 1:
      if costs[0] >= 0:
        candidate = costs[0] + best[l]
        if candidate < Inf and candidate < best[i]: best[i] = candidate; choice[i] = 0
    else:
      if costs[1] >= 0:
        candidate = costs[1] + best[l] + best[r]
        if candidate < Inf and candidate < best[i]: best[i] = candidate; choice[i] = 1
      if costs[2] >= 0 and kind[l] == 1:
        candidate = costs[2] + best[left[l]] + best[r]
        if candidate < Inf and candidate < best[i]: best[i] = candidate; choice[i] = 2
      if costs[3] >= 0 and kind[r] == 1:
        candidate = costs[3] + best[l] + best[left[r]]
        if candidate < Inf and candidate < best[i]: best[i] = candidate; choice[i] = 3
      if costs[4] >= 0 and kind[l] == 1 and kind[r] == 1:
        candidate = costs[4] + best[left[l]] + best[left[r]]
        if candidate < Inf and candidate < best[i]: best[i] = candidate; choice[i] = 4
  if best[0] == Inf: return -1
  var mapping: array[MaxN, int]
  for i in 0..<n: mapping[i] = if kind[i] == 0: -1 else: -3
  var stack: array[2 * MaxN, int]
  var top = 0
  if kind[0] != 0: stack[top] = 0; inc top
  while top > 0:
    dec top
    let node = stack[top]; let p = choice[node]; let l, r = left[node], right[node]
    mapping[node] = p
    if p == 0: stack[top] = l; inc top
    elif p == 1: stack[top] = l; inc top; stack[top] = r; inc top
    elif p == 2: mapping[l] = -2; stack[top] = left[l]; inc top; stack[top] = r; inc top
    elif p == 3: mapping[r] = -2; stack[top] = l; inc top; stack[top] = left[r]; inc top
    else: mapping[l] = -2; mapping[r] = -2; stack[top] = left[l]; inc top; stack[top] = left[r]; inc top
  let bytes = 8 * (n + 1)
  if output.isNil or capacity < csize_t(bytes): return -2
  var staged: array[MaxOutput, uint8]
  put(addr staged[0], 0, best[0])
  for i in 0..<n: put(addr staged[0], 8 * (i + 1), int64(mapping[i]))
  for i in 0..<bytes: output[i] = staged[i]
  int64(bytes)
