## Uncompiled half-GCD resultant draft.
const P = 998244353'i64
type
  Poly = seq[int64]
  Matrix = object
    a, b, c, d: Poly
  Head = tuple[degree: int, leading: int64]

proc power(baseValue: int64, exponentValue: int): int64 =
  var base = baseValue
  var exponent = exponentValue
  result = 1
  while exponent > 0:
    if (exponent and 1) != 0: result = result * base mod P
    base = base * base mod P
    exponent = exponent shr 1

proc trim(a: var Poly) =
  while a.len > 0 and a[^1] == 0: a.setLen(a.len - 1)

proc transform(a: var Poly, inverse: bool) =
  let n = a.len
  var j = 0
  for i in 1 ..< n:
    var bit = n shr 1
    while (j and bit) != 0:
      j = j xor bit
      bit = bit shr 1
    j = j xor bit
    if i < j: swap(a[i], a[j])
  var width = 2
  while width <= n:
    var root = power(3, int((P - 1) div int64(width)))
    if inverse: root = power(root, int(P - 2))
    var base = 0
    while base < n:
      var factor = 1'i64
      for k in 0 ..< width div 2:
        let x = a[base + k]
        let y = a[base + k + width div 2] * factor mod P
        a[base + k] = (x + y) mod P
        a[base + k + width div 2] = (x - y + P) mod P
        factor = factor * root mod P
      base += width
    width *= 2
  if inverse:
    let scale = power(int64(n), int(P - 2))
    for x in a.mitems: x = x * scale mod P

proc mul(a, b: Poly): Poly =
  if a.len == 0 or b.len == 0: return @[]
  let count = a.len + b.len - 1
  if min(a.len, b.len) <= 32:
    result = newSeq[int64](count)
    for i in 0 ..< a.len:
      for j in 0 ..< b.len:
        result[i+j] = (result[i+j] + a[i] * b[j]) mod P
  else:
    var n = 1
    while n < count: n *= 2
    var x = newSeq[int64](n)
    var y = newSeq[int64](n)
    for i in 0 ..< a.len: x[i] = a[i]
    for i in 0 ..< b.len: y[i] = b[i]
    transform(x, false)
    transform(y, false)
    for i in 0 ..< n: x[i] = x[i] * y[i] mod P
    transform(x, true)
    x.setLen(count)
    result = x
  trim(result)

proc add(a, b: Poly): Poly =
  result = newSeq[int64](max(a.len, b.len))
  for i in 0 ..< a.len: result[i] = a[i]
  for i in 0 ..< b.len: result[i] = (result[i] + b[i]) mod P
  trim(result)

proc divrem(a, b: Poly): tuple[q, r: Poly] =
  if a.len < b.len: return (@[], a)
  let count = a.len - b.len + 1
  var high = newSeq[int64](count)
  var reversed = newSeq[int64](b.len)
  for i in 0 ..< count: high[i] = a[a.len - 1 - i]
  for i in 0 ..< b.len: reversed[i] = b[b.len - 1 - i]
  var inverse = @[power(reversed[0], int(P - 2))]
  while inverse.len < count:
    let size = min(count, 2 * inverse.len)
    var prefix = newSeq[int64](min(size, reversed.len))
    for i in 0 ..< prefix.len: prefix[i] = reversed[i]
    var correction = mul(prefix, inverse)
    correction.setLen(size)
    for x in correction.mitems: x = (P - x) mod P
    correction[0] = (correction[0] + 2) mod P
    inverse = mul(inverse, correction)
    inverse.setLen(size)
  var reversedQ = mul(high, inverse)
  reversedQ.setLen(count)
  var q = newSeq[int64](count)
  for i in 0 ..< count: q[i] = reversedQ[count - 1 - i]
  let removed = mul(q, b)
  var r = newSeq[int64](b.len - 1)
  for i in 0 ..< r.len:
    let value = if i < removed.len: removed[i] else: 0'i64
    r[i] = (a[i] - value + P) mod P
  trim(q)
  trim(r)
  (q, r)

proc identity(): Matrix = Matrix(a: @[1'i64], d: @[1'i64])

proc step(q: Poly): Matrix =
  result.b = @[1'i64]
  result.c = @[1'i64]
  result.d = newSeq[int64](q.len)
  for i in 0 ..< q.len: result.d[i] = (P - q[i]) mod P

proc compose(x, y: Matrix): Matrix =
  Matrix(a: add(mul(x.a,y.a), mul(x.b,y.c)),
         b: add(mul(x.a,y.b), mul(x.b,y.d)),
         c: add(mul(x.c,y.a), mul(x.d,y.c)),
         d: add(mul(x.c,y.b), mul(x.d,y.d)))

proc apply(m: Matrix, a, b: Poly): tuple[x, y: Poly] =
  (add(mul(m.a,a), mul(m.b,b)), add(mul(m.c,a), mul(m.d,b)))

proc upper(a: Poly, shift: int): Poly =
  if shift >= a.len: return @[]
  result = newSeq[int64](a.len - shift)
  for i in 0 ..< result.len: result[i] = a[i + shift]

proc halfReduce(a, b: Poly, heads: var seq[Head]): Matrix =
  if b.len == 0: return identity()
  let degree = a.len - 1
  let threshold = (degree + 1) div 2
  if b.len <= threshold: return identity()
  if degree <= 64:
    var x = a
    var y = b
    result = identity()
    while y.len > threshold and y.len > 0:
      let division = divrem(x, y)
      heads.add((division.q.len - 1, division.q[^1]))
      result = compose(step(division.q), result)
      x = y
      y = division.r
    return
  let first = halfReduce(upper(a, threshold), upper(b, threshold), heads)
  let reduced = apply(first, a, b)
  if reduced.y.len == 0 or reduced.y.len <= threshold: return first
  let division = divrem(reduced.x, reduced.y)
  heads.add((division.q.len - 1, division.q[^1]))
  let prefix = compose(step(division.q), first)
  if division.r.len == 0: return prefix
  let shift = 2 * threshold - (reduced.y.len - 1)
  let highR = upper(division.r, shift)
  if highR.len == 0: return prefix
  compose(halfReduce(upper(reduced.y, shift), highR, heads), prefix)

proc resultant(first, second: Poly): int64 =
  var a = first
  var b = second
  result = 1
  if a.len < b.len:
    if ((a.len - 1) and 1) != 0 and ((b.len - 1) and 1) != 0: result = P - result
    swap(a, b)
  while true:
    if b.len == 1: return result * power(b[0], a.len - 1) mod P
    var heads: seq[Head] = @[]
    var reduced: tuple[x, y: Poly]
    if a.len != b.len:
      let matrix = halfReduce(a, b, heads)
      if heads.len > 0: reduced = apply(matrix, a, b)
    if heads.len == 0:
      let division = divrem(a, b)
      if division.r.len == 0: return 0
      let da = a.len - 1
      let db = b.len - 1
      let dr = division.r.len - 1
      if (da and 1) != 0 and (db and 1) != 0: result = P - result
      result = result * power(b[^1], da - dr) mod P
      a = b
      b = division.r
    else:
      if reduced.y.len == 0: return 0
      var da = a.len - 1
      var db = b.len - 1
      var lead = b[^1]
      for i in 0 ..< heads.len:
        let last = i + 1 == heads.len
        let dr = if last: reduced.y.len - 1 else: db - heads[i + 1].degree
        if (da and 1) != 0 and (db and 1) != 0: result = P - result
        result = result * power(lead, da - dr) mod P
        if not last: lead = lead * power(heads[i + 1].leading, int(P - 2)) mod P
        da = db
        db = dr
      a = reduced.x
      b = reduced.y

proc polynomial_resultant_half_gcd*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "polynomial_resultant_half_gcd".} =
  if input.isNil or length < 4 or length > 100002: return -1
  let m = input[0]
  let n = input[1]
  if m < 0 or m > 50000 or n < 0 or n > 50000 or m + n > 99998: return -1
  let firstLen = int(m) + 1
  let secondLen = int(n) + 1
  if length != csize_t(firstLen + secondLen + 2): return -1
  var a = newSeq[int64](firstLen)
  var b = newSeq[int64](secondLen)
  for i in 0 ..< firstLen:
    a[i] = input[2 + i]
    if a[i] < 0 or a[i] >= P: return -1
  for i in 0 ..< secondLen:
    b[i] = input[2 + firstLen + i]
    if b[i] < 0 or b[i] >= P: return -1
  if a[^1] == 0 or b[^1] == 0: return -1
  resultant(a, b)
