## Independent NTT and product-tree difference product draft; see README.
const Modulus = 998244353'i64

proc fieldPower(baseValue, exponentValue: int64): int64 =
  var base = baseValue
  var exponent = exponentValue
  result = 1
  while exponent > 0:
    if (exponent and 1) != 0: result = result * base mod Modulus
    base = base * base mod Modulus
    exponent = exponent shr 1

proc transform(values: var seq[int64], inverse: bool) =
  let n = values.len
  var reversed = 0
  for i in 1 ..< n:
    var bit = n shr 1
    while (reversed and bit) != 0:
      reversed = reversed xor bit
      bit = bit shr 1
    reversed = reversed xor bit
    if i < reversed: swap(values[i], values[reversed])
  var width = 2
  while width <= n:
    var step = fieldPower(3, (Modulus - 1) div int64(width))
    if inverse: step = fieldPower(step, Modulus - 2)
    var start = 0
    while start < n:
      var root = 1'i64
      for j in 0 ..< width div 2:
        let a = values[start + j]
        let b = values[start + j + width div 2] * root mod Modulus
        values[start + j] = (a + b) mod Modulus
        values[start + j + width div 2] = (a - b + Modulus) mod Modulus
        root = root * step mod Modulus
      start += width
    width *= 2
  if inverse:
    let scale = fieldPower(int64(n), Modulus - 2)
    for i in 0 ..< n: values[i] = values[i] * scale mod Modulus

proc multiply(a, b: seq[int64]): seq[int64] =
  if a.len == 0 or b.len == 0: return @[]
  let needed = a.len + b.len - 1
  if min(a.len, b.len) <= 32:
    result = newSeq[int64](needed)
    for i in 0 ..< a.len:
      for j in 0 ..< b.len:
        result[i + j] = (result[i + j] + a[i] * b[j]) mod Modulus
    return
  var size = 1
  while size < needed: size *= 2
  var left = newSeq[int64](size)
  var right = newSeq[int64](size)
  for i in 0 ..< a.len: left[i] = a[i]
  for i in 0 ..< b.len: right[i] = b[i]
  transform(left, false)
  transform(right, false)
  for i in 0 ..< size: left[i] = left[i] * right[i] mod Modulus
  transform(left, true)
  left.setLen(needed)
  result = left

proc seriesInverse(f: seq[int64], count: int): seq[int64] =
  result = @[fieldPower(f[0], Modulus - 2)]
  while result.len < count:
    let n = min(count, 2 * result.len)
    var prefix = newSeq[int64](min(n, f.len))
    for i in 0 ..< prefix.len: prefix[i] = f[i]
    var correction = multiply(prefix, result)
    correction.setLen(n)
    for i in 0 ..< n: correction[i] = (Modulus - correction[i]) mod Modulus
    correction[0] = (correction[0] + 2) mod Modulus
    result = multiply(result, correction)
    result.setLen(n)

proc polyRemainder(dividend, divisor: seq[int64]): seq[int64] =
  if dividend.len < divisor.len: return dividend
  if divisor.len == 1: return @[]
  let quotientLen = dividend.len - divisor.len + 1
  var high = newSeq[int64](quotientLen)
  var reversedDivisor = newSeq[int64](divisor.len)
  for i in 0 ..< quotientLen: high[i] = dividend[dividend.len - i - 1]
  for i in 0 ..< divisor.len: reversedDivisor[i] = divisor[divisor.len - i - 1]
  let inverse = seriesInverse(reversedDivisor, quotientLen)
  let reversedQuotient = multiply(high, inverse)
  var quotient = newSeq[int64](quotientLen)
  for i in 0 ..< quotientLen: quotient[i] = reversedQuotient[quotientLen - i - 1]
  let removed = multiply(quotient, divisor)
  result = newSeq[int64](divisor.len - 1)
  for i in 0 ..< result.len:
    result[i] = (dividend[i] - removed[i] + Modulus) mod Modulus
  while result.len > 0 and result[^1] == 0: result.setLen(result.len - 1)

type PointTree = object
  size, count: int
  nodes: seq[seq[int64]]

proc makeTree(points: seq[int64]): PointTree =
  result.size = 1
  result.count = points.len
  while result.size < points.len: result.size *= 2
  result.nodes = newSeq[seq[int64]](2 * result.size)
  for i in 0 ..< result.size:
    if i < points.len: result.nodes[result.size + i] = @[(Modulus - points[i]) mod Modulus, 1'i64]
    else: result.nodes[result.size + i] = @[1'i64]
  var node = result.size - 1
  while node > 0:
    result.nodes[node] = multiply(result.nodes[2 * node], result.nodes[2 * node + 1])
    dec node

proc visit(tree: PointTree, node: int, value: seq[int64], output: var seq[int64]) =
  if node >= tree.size:
    let index = node - tree.size
    if index < tree.count and value.len > 0: output[index] = value[0]
    return
  visit(tree, node * 2, polyRemainder(value, tree.nodes[node * 2]), output)
  visit(tree, node * 2 + 1, polyRemainder(value, tree.nodes[node * 2 + 1]), output)

proc orderedProduct(points: seq[int64]): int64 =
  if points.len <= 32:
    result = 1
    for i in 0 ..< points.len:
      for j in i + 1 ..< points.len:
        result = result * ((points[i] - points[j] + Modulus) mod Modulus) mod Modulus
    return
  let mid = points.len div 2
  let left = points[0 ..< mid]
  let right = points[mid ..< points.len]
  result = orderedProduct(left) * orderedProduct(right) mod Modulus
  if result == 0: return
  let leftTree = makeTree(left)
  let rightTree = makeTree(right)
  var evaluations = newSeq[int64](right.len)
  visit(rightTree, 1, polyRemainder(leftTree.nodes[1], rightTree.nodes[1]), evaluations)
  for value in evaluations: result = result * value mod Modulus
  if (left.len and 1) != 0 and (right.len and 1) != 0 and result != 0:
    result = Modulus - result

proc difference_product*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "difference_product".} =
  if input.isNil or length == 0 or input[0] < 0 or input[0] > 65536: return -1
  let count = int(input[0])
  if length != csize_t(count + 1): return -1
  var values = newSeq[int64](count)
  for i in 0 ..< count:
    if input[i + 1] < 0 or input[i + 1] >= Modulus: return -1
    values[i] = input[i + 1]
  result = orderedProduct(values)
