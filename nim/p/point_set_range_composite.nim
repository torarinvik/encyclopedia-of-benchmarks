const
  Modulus = 998_244_353'i64
  MaxN = 16
  MaxOperations = 32
  MaxInputLength = 162
  TreeCapacity = 64

type
  AffineMap = object
    a, b: int64

proc identityMap(): AffineMap = AffineMap(a: 1, b: 0)

proc compose(left, right: AffineMap): AffineMap =
  AffineMap(
    a: (right.a * left.a) mod Modulus,
    b: (right.a * left.b + right.b) mod Modulus,
  )

proc point_set_range_composite*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "point_set_range_composite".} =
  if values == nil or length < 2 or length > csize_t(MaxInputLength): return -1
  let nValue = values[0]
  let qValue = values[1]
  if nValue < 1 or nValue > MaxN or qValue < 0 or qValue > MaxOperations: return -1
  let n = int(nValue)
  let q = int(qValue)
  if int(length) != 2 + 2 * n + 4 * q: return -1

  for index in 0 ..< n:
    let a = values[2 + 2 * index]
    let b = values[3 + 2 * index]
    if a < 0 or a >= Modulus or b < 0 or b >= Modulus: return -1

  var base = 1
  while base < n: base *= 2
  var tree: array[TreeCapacity, AffineMap]
  for node in 0 ..< TreeCapacity: tree[node] = identityMap()
  for index in 0 ..< n:
    tree[base + index] = AffineMap(a: values[2 + 2 * index], b: values[3 + 2 * index])
  var node = base
  while node > 1:
    dec node
    tree[node] = compose(tree[2 * node], tree[2 * node + 1])

  var checksum = 0'i64
  var queryNumber = 0'i64
  var cursor = 2 + 2 * n
  for _ in 0 ..< q:
    let opcode = values[cursor]
    let first = values[cursor + 1]
    let second = values[cursor + 2]
    let third = values[cursor + 3]
    cursor += 4
    if opcode == 0:
      if first < 0 or first >= nValue or second < 0 or second >= Modulus or
          third < 0 or third >= Modulus: return -1
      var node = base + int(first)
      tree[node] = AffineMap(a: second, b: third)
      while node > 1:
        node = node div 2
        tree[node] = compose(tree[2 * node], tree[2 * node + 1])
    elif opcode == 1:
      if first < 0 or first > second or second > nValue or third < 0 or third >= Modulus: return -1
      var leftIndex = base + int(first)
      var rightIndex = base + int(second)
      var left = identityMap()
      var right = identityMap()
      while leftIndex < rightIndex:
        if (leftIndex and 1) == 1:
          left = compose(left, tree[leftIndex])
          inc leftIndex
        if (rightIndex and 1) == 1:
          dec rightIndex
          right = compose(tree[rightIndex], right)
        leftIndex = leftIndex div 2
        rightIndex = rightIndex div 2
      let combined = compose(left, right)
      let answer = (combined.a * third + combined.b) mod Modulus
      inc queryNumber
      checksum = (checksum + queryNumber * answer) mod Modulus
    else:
      return -1
  if cursor != int(length): return -1
  checksum
