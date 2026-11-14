proc xor_filter_peeling*(input: ptr UncheckedArray[int64], length: csize_t): int64 {.cdecl, exportc: "xor_filter_peeling".} =
  if input == nil or length < 3 or length > 259 or input[0] < 0 or input[0] > 32 or input[1] < 3 or input[1] > 96 or input[2] < 0 or input[2] > 32: return -1
  let n = int(input[0])
  let slots = int(input[1])
  let q = int(input[2])
  if int(length) != 3+4*(n+q): return -1
  for i in 0 ..< n+q:
    let at = 3+4*i
    let a = input[at]
    let b = input[at+1]
    let c = input[at+2]
    let f = input[at+3]
    if a < 0 or a >= int64(slots) or b < 0 or b >= int64(slots) or c < 0 or c >= int64(slots) or a == b or a == c or b == c or f < 0 or f > 255: return -1
  var degree, edgeXor, queue, table: array[96, int]
  var stackSlot, stackEdge: array[32, int]
  for edge in 0 ..< n:
    for j in 0 ..< 3:
      let slot = int(input[3+4*edge+j])
      inc degree[slot]
      edgeXor[slot] = edgeXor[slot] xor edge
  var head = 0
  var tail = 0
  var used = 0
  for slot in 0 ..< slots:
    if degree[slot] == 1:
      queue[tail] = slot
      inc tail
  while head < tail:
    let slot = queue[head]
    inc head
    if degree[slot] != 1: continue
    let edge = edgeXor[slot]
    stackSlot[used] = slot
    stackEdge[used] = edge
    inc used
    for j in 0 ..< 3:
      let v = int(input[3+4*edge+j])
      dec degree[v]
      edgeXor[v] = edgeXor[v] xor edge
      if degree[v] == 1:
        queue[tail] = v
        inc tail
  if used != n: return -2
  while used > 0:
    dec used
    let at = 3+4*stackEdge[used]
    let a = int(input[at])
    let b = int(input[at+1])
    let c = int(input[at+2])
    table[stackSlot[used]] = int(input[at+3]) xor table[a] xor table[b] xor table[c]
  var total = 0'i64
  for i in 0 ..< q:
    let at = 3+4*(n+i)
    let a = int(input[at])
    let b = int(input[at+1])
    let c = int(input[at+2])
    if (table[a] xor table[b] xor table[c]) == int(input[at+3]): total += int64(i+1)
  total
