## Uncompiled bounded GF(2) quadratic-form normal-form draft.
type Vec = array[2, uint64]
type Rows = array[100, Vec]

proc bit(v: Vec, i: int): bool = (v[i div 64] and (1'u64 shl (i mod 64))) != 0
proc put(v: var Vec, i: int) = v[i div 64] = v[i div 64] or (1'u64 shl (i mod 64))
proc xorVec(a, b: Vec): Vec = [a[0] xor b[0], a[1] xor b[1]]
proc parity(v: uint64): int =
  var x = v
  x = x xor (x shr 32); x = x xor (x shr 16); x = x xor (x shr 8)
  x = x xor (x shr 4); x = x xor (x shr 2); x = x xor (x shr 1)
  int(x and 1'u64)
proc apply(rows: Rows, n: int, a, b: Vec): int =
  for i in 0 ..< n:
    if bit(a, i): result = result xor parity((rows[i][0] and b[0]) xor (rows[i][1] and b[1]))

proc quadratic_form_gf2_normal_form*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "quadratic_form_gf2_normal_form".} =
  if input == nil or length < 1 or length > 202 or input[0] < 1 or input[0] > 100: return -1
  let n = int(input[0])
  let words = (n + 62) div 63
  if length != csize_t(1 + n * words): return -1
  var upper, bilinear: Rows
  for i in 0 ..< n:
    for chunk in 0 ..< words:
      let raw = input[1 + i * words + chunk]
      if raw < 0: return -1
      for b in 0 ..< 63:
        if ((uint64(raw) shr b) and 1'u64) == 0: continue
        let j = 63 * chunk + b
        if j >= n or j < i: return -1
        put(upper[i], j)
        if i != j:
          put(bilinear[i], j)
          put(bilinear[j], i)
  let rowBytes = (n + 7) div 8
  let needed = 3 + n * rowBytes
  if output == nil or capacity < csize_t(needed): return -2
  var remaining, hyper, anis, columns: Rows
  for i in 0 ..< n: put(remaining[i], i)
  var count = n
  var hc = 0
  var ac = 0
  while true:
    var left = count
    var right = count
    for i in 0 ..< count:
      for j in i + 1 ..< count:
        if apply(bilinear, n, remaining[i], remaining[j]) != 0:
          left = i; right = j; break
      if left != count: break
    if left == count: break
    var u = remaining[left]
    var v = remaining[right]
    var rest: Rows
    var next = 0
    for i in 0 ..< count:
      if i == left or i == right: continue
      var w = remaining[i]
      if apply(bilinear, n, remaining[i], v) != 0: w = xorVec(w, u)
      if apply(bilinear, n, remaining[i], u) != 0: w = xorVec(w, v)
      rest[next] = w; inc next
    remaining = rest; count = next
    let qu = apply(upper, n, u, u)
    let qv = apply(upper, n, v, v)
    if qu != 0 and qv != 0:
      anis[ac] = u; anis[ac + 1] = v; ac += 2
    else:
      if qu != 0: u = xorVec(u, v)
      elif qv != 0: v = xorVec(v, u)
      hyper[hc] = u; hyper[hc + 1] = v; hc += 2
  while ac >= 4:
    let a = anis[ac - 2]; let b = anis[ac - 1]
    let c = anis[ac - 4]; let d = anis[ac - 3]
    ac -= 4
    let f = xorVec(d, xorVec(a, b))
    hyper[hc] = xorVec(a, c); hyper[hc + 1] = xorVec(b, c)
    hyper[hc + 2] = f; hyper[hc + 3] = xorVec(f, c); hc += 4
  var linear: Vec
  var hasLinear = false
  for i in 0 ..< count:
    if apply(upper, n, remaining[i], remaining[i]) != 0:
      linear = remaining[i]; hasLinear = true
      for j in i + 1 ..< count: remaining[j - 1] = remaining[j]
      dec count
      break
  if hasLinear:
    for i in 0 ..< count:
      if apply(upper, n, remaining[i], remaining[i]) != 0: remaining[i] = xorVec(remaining[i], linear)
    if ac != 0:
      hyper[hc] = xorVec(anis[0], linear); hyper[hc + 1] = xorVec(anis[1], linear)
      hc += 2; ac = 0
  var used = 0
  for i in 0 ..< hc: columns[used] = hyper[i]; inc used
  for i in 0 ..< ac: columns[used] = anis[i]; inc used
  if hasLinear: columns[used] = linear; inc used
  for i in 0 ..< count: columns[used] = remaining[i]; inc used
  if used != n or hc mod 2 != 0 or (ac != 0 and ac != 2): return -4
  var matrix, inverse: Rows
  for i in 0 ..< n:
    put(inverse[i], i)
    for j in 0 ..< n:
      if bit(columns[j], i): put(matrix[i], j)
  for col in 0 ..< n:
    var pivot = col
    while pivot < n and not bit(matrix[pivot], col): inc pivot
    if pivot == n: return -4
    swap(matrix[col], matrix[pivot]); swap(inverse[col], inverse[pivot])
    for row in 0 ..< n:
      if row != col and bit(matrix[row], col):
        matrix[row] = xorVec(matrix[row], matrix[col])
        inverse[row] = xorVec(inverse[row], inverse[col])
  var staged: array[1303, uint8]
  staged[0] = uint8(hc div 2); staged[1] = uint8(ac div 2)
  if hasLinear: staged[2] = 1
  for i in 0 ..< n:
    for j in 0 ..< n:
      if bit(inverse[i], j): staged[3 + i * rowBytes + j div 8] = staged[3 + i * rowBytes + j div 8] or uint8(1 shl (j mod 8))
  for i in 0 ..< needed: output[i] = staged[i]
  int64(needed)
