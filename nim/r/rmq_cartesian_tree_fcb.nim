const N = 64
const Q = 64
const E = 127
const B = 127
const L = 8
const M = 4

proc shallower(depth: array[E, uint16], a, b: int): int =
  if depth[a] < depth[b] or (depth[a] == depth[b] and a < b): a else: b

proc rmq(a, z, ec, bs: int, depth: array[E, uint16], pat: array[B, uint8],
    micro: array[8, array[M, array[M, uint8]]], macroTable: array[L, array[B, uint16]],
    logs: array[B + 1, uint8]): int =
  let ba = a div bs
  let bz = z div bs
  let oa = a mod bs
  let oz = z mod bs
  if ba == bz: return ba * bs + int(micro[int(pat[ba])][oa][oz])
  let xa = ba * bs
  let xz = bz * bs
  let na = min(bs, ec - xa)
  var best = xa + int(micro[int(pat[ba])][oa][na - 1])
  best = shallower(depth, best, xz + int(micro[int(pat[bz])][0][oz]))
  if bz > ba + 1:
    let lo = ba + 1
    let hi = bz - 1
    let k = int(logs[hi - lo + 1])
    let span = 1 shl k
    best = shallower(depth, best, int(macroTable[k][lo]))
    best = shallower(depth, best, int(macroTable[k][hi - span + 1]))
  best

proc rmq_cartesian_tree_fcb*(input: ptr UncheckedArray[int64], inputLength: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "rmq_cartesian_tree_fcb".} =
  if input.isNil or inputLength < 2 or inputLength > 195: return -1
  if input[0] < 1 or input[0] > N or input[1] < 0 or input[1] > Q: return -1
  let n = int(input[0])
  let q = int(input[1])
  let qo = 2 + n
  if inputLength != csize_t(qo + 2 * q): return -1
  var values: array[N, int64]
  for i in 0 ..< n:
    values[i] = input[2 + i]
    if values[i] < -1000 or values[i] > 1000: return -1
  for i in 0 ..< q:
    let a = input[qo + 2 * i]
    let z = input[qo + 2 * i + 1]
    if a < 0 or a > z or z >= int64(n): return -1
  if output.isNil or outputCapacity < csize_t(q + 1): return -2

  var left, right, parent: array[N, int]
  var mono: array[N, int]
  for i in 0 ..< n: left[i] = -1; right[i] = -1; parent[i] = -1
  var top = 0
  for i in 0 ..< n:
    var last = -1
    while top > 0 and values[mono[top - 1]] > values[i]:
      dec top
      last = mono[top]
    if top > 0:
      let p = mono[top - 1]
      right[p] = i
      parent[i] = p
    if last >= 0: left[i] = last; parent[last] = i
    mono[top] = i
    inc top
  var root = 0
  while parent[root] >= 0: inc root

  var euler, depth: array[E, uint16]
  var first, nodeDepth, frameNode: array[N, int]
  var frameState: array[N, uint8]
  var ec = 1
  var sp = 1
  euler[0] = uint16(root)
  depth[0] = 0
  first[root] = 0
  nodeDepth[root] = 0
  frameNode[0] = root
  while sp > 0:
    let slot = sp - 1
    let v = frameNode[slot]
    if frameState[slot] == 0:
      if left[v] >= 0:
        let c = left[v]
        frameState[slot] = 1
        nodeDepth[c] = nodeDepth[v] + 1
        first[c] = ec
        euler[ec] = uint16(c); depth[ec] = uint16(nodeDepth[c]); inc ec
        frameNode[sp] = c; frameState[sp] = 0; inc sp
      elif right[v] >= 0:
        let c = right[v]
        frameState[slot] = 2
        nodeDepth[c] = nodeDepth[v] + 1
        first[c] = ec
        euler[ec] = uint16(c); depth[ec] = uint16(nodeDepth[c]); inc ec
        frameNode[sp] = c; frameState[sp] = 0; inc sp
      else: dec sp
    elif frameState[slot] == 1:
      euler[ec] = uint16(v); depth[ec] = uint16(nodeDepth[v]); inc ec
      if right[v] >= 0:
        let c = right[v]
        frameState[slot] = 2
        nodeDepth[c] = nodeDepth[v] + 1
        first[c] = ec
        euler[ec] = uint16(c); depth[ec] = uint16(nodeDepth[c]); inc ec
        frameNode[sp] = c; frameState[sp] = 0; inc sp
      else: dec sp
    else:
      euler[ec] = uint16(v); depth[ec] = uint16(nodeDepth[v]); inc ec
      dec sp

  var lg = 0
  var tmp = ec
  while tmp > 1: tmp = tmp div 2; inc lg
  let bs = max(1, lg div 2)
  let blocks = (ec + bs - 1) div bs
  var micro: array[8, array[M, array[M, uint8]]]
  var pat: array[B, uint8]
  var logs: array[B + 1, uint8]
  var macroTable: array[L, array[B, uint16]]
  for shape in 0 ..< (1 shl (bs - 1)):
    var rel: array[M, int]
    for j in 0 ..< bs - 1: rel[j + 1] = rel[j] + (if (shape and (1 shl j)) != 0: 1 else: -1)
    for a in 0 ..< bs:
      for z in a ..< bs:
        var best = a
        for k in a + 1 .. z:
          if rel[k] < rel[best]: best = k
        micro[shape][a][z] = uint8(best)
  for b in 0 ..< blocks:
    let base = b * bs
    let endAt = min(ec, base + bs)
    var best = base
    for j in base ..< endAt - 1:
      if depth[j + 1] > depth[j]: pat[b] = pat[b] or uint8(1 shl (j - base))
      best = shallower(depth, best, j + 1)
    macroTable[0][b] = uint16(best)
  if blocks > 0: logs[1] = 0
  for c in 2 .. blocks: logs[c] = logs[c div 2] + 1
  var level = 1
  while (1 shl level) <= blocks and level < L:
    let half = 1 shl (level - 1)
    let span = 2 * half
    for b in 0 .. blocks - span:
      macroTable[level][b] = uint16(shallower(depth, int(macroTable[level - 1][b]), int(macroTable[level - 1][b + half])))
    inc level
  var answers: array[Q, uint8]
  for i in 0 ..< q:
    var a = first[int(input[qo + 2 * i])]
    var z = first[int(input[qo + 2 * i + 1])]
    if a > z: swap(a, z)
    answers[i] = uint8(euler[rmq(a, z, ec, bs, depth, pat, micro, macroTable, logs)])
  output[0] = uint8(q)
  for i in 0 ..< q: output[i + 1] = answers[i]
  int64(q + 1)
