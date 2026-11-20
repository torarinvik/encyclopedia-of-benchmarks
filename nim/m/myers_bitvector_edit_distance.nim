## Uncompiled multiword bit-vector global edit-distance draft.
proc myers_bitvector_edit_distance*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "myers_bitvector_edit_distance".} =
  if input == nil or length < 2 or length > 515: return -1
  let nr = input[0]
  let mr = input[1]
  if nr < 0 or nr > 256 or mr < 0 or mr > 256 or length != csize_t(2+nr+mr): return -1
  let n = int(nr)
  let m = int(mr)
  for i in 2 ..< int(length):
    if input[i] < 0 or input[i] > 255: return -1
  if n == 0: return mr
  var masks: array[256, array[4, uint64]]
  var pv, mv: array[4, uint64]
  let words = (n+63) div 64
  for j in 0 ..< words: pv[j] = not 0'u64
  for i in 0 ..< n: masks[int(input[2+i])][i div 64] = masks[int(input[2+i])][i div 64] or (1'u64 shl (i mod 64))
  var score = nr
  let top = 1'u64 shl ((n-1) mod 64)
  for i in 0 ..< m:
    let symbol = int(input[2+n+i])
    var add = 0'u64
    var pc = 1'u64
    var mc = 0'u64
    for j in 0 ..< words:
      let eq = masks[symbol][j]
      let p = pv[j]
      let v = mv[j]
      let term = eq and p
      let limit = not 0'u64
      let carry1 = p > limit-term
      let first = if carry1: p-(limit-term)-1'u64 else: p+term
      let carry2 = add != 0 and first == limit
      let sum = if carry2: 0'u64 else: first+add
      add = if carry1 or carry2: 1'u64 else: 0'u64
      let xh = (sum xor p) or eq
      let xv = eq or v
      var ph = v or (not (xh or p))
      var mh = p and xh
      if j == words-1:
        if (ph and top) != 0: inc score
        if (mh and top) != 0: dec score
      let nextPc = ph shr 63
      let nextMc = mh shr 63
      ph = (ph shl 1) or pc
      mh = (mh shl 1) or mc
      pc = nextPc
      mc = nextMc
      pv[j] = mh or (not (xv or ph))
      mv[j] = ph and xv
  score
