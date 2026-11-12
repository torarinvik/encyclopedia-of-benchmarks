const
  MaxN = 32
  MaxQ = 64
  Modulus = 998_244_353'i64

type Matrix = array[4, int64]

proc normalize(valueInput: int64): int64 =
  result = valueInput mod Modulus
  if result < 0: result += Modulus

proc multiply(left, right: Matrix): Matrix =
  for row in 0 .. 1:
    for column in 0 .. 1:
      for inner in 0 .. 1:
        result[2 * row + column] = normalize(result[2 * row + column] +
          left[2 * row + inner] * right[2 * inner + column])

proc inverse(matrix: Matrix): Matrix =
  [matrix[3], normalize(-matrix[1]), normalize(-matrix[2]), matrix[0]]

proc findRoot(parent: var array[MaxN, int], difference: var array[MaxN, Matrix], item: int): int =
  if parent[item] != item:
    let oldParent = parent[item]
    let root = findRoot(parent, difference, oldParent)
    difference[item] = multiply(difference[oldParent], difference[item])
    parent[item] = root
  parent[item]

proc putI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8: output[offset + byte] = uint8((bits shr (8 * byte)) and 255)

proc unionfind_with_potential_non_commutative_group*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc: "unionfind_with_potential_non_commutative_group".} =
  if input.isNil or length < csize_t(9) or length > csize_t(2 + 7 * MaxQ): return -1
  let n64 = input[0]
  let q64 = input[1]
  if n64 < 1 or n64 > int64(MaxN) or q64 < 1 or q64 > int64(MaxQ): return -1
  let n = int(n64)
  let q = int(q64)
  if int(length) != 2 + 7 * q: return -1
  for operation in 0 ..< q:
    let position = 2 + 7 * operation
    let kind = input[position]
    let u = input[position + 1]
    let v = input[position + 2]
    if u < 0 or u >= n64 or v < 0 or v >= n64: return -1
    if kind == 0:
      let a = input[position + 3]
      let b = input[position + 4]
      let c = input[position + 5]
      let d = input[position + 6]
      if a < 0 or a >= Modulus or b < 0 or b >= Modulus or c < 0 or c >= Modulus or d < 0 or d >= Modulus or normalize(a * d - b * c) != 1: return -1
    elif kind == 1:
      for cell in 0 ..< 4:
        if input[position + 3 + cell] != 0: return -1
    else:
      return -1
  let required = 32 * q
  if output.isNil or capacity < csize_t(required): return -2

  var parent: array[MaxN, int]
  var setSize: array[MaxN, int]
  var difference: array[MaxN, Matrix]
  for item in 0 ..< n:
    parent[item] = item
    setSize[item] = 1
    difference[item] = [1'i64, 0, 0, 1]
  for operation in 0 ..< q:
    let position = 2 + 7 * operation
    let kind = input[position]
    let u = int(input[position + 1])
    let v = int(input[position + 2])
    var row: Matrix = [0'i64, 0, 0, 0]
    let rootU = findRoot(parent, difference, u)
    let rootV = findRoot(parent, difference, v)
    if kind == 1:
      if rootU == rootV:
        row = multiply(inverse(difference[v]), difference[u])
      else:
        row = [-1'i64, -1, -1, -1]
    else:
      let relation: Matrix = [input[position + 3], input[position + 4], input[position + 5], input[position + 6]]
      if rootU == rootV:
        row[0] = int64(multiply(inverse(difference[v]), difference[u]) == relation)
      elif setSize[rootU] < setSize[rootV]:
        difference[rootU] = multiply(multiply(difference[v], relation), inverse(difference[u]))
        parent[rootU] = rootV
        setSize[rootV] += setSize[rootU]
        row[0] = 1
      else:
        difference[rootV] = multiply(multiply(difference[u], inverse(relation)), inverse(difference[v]))
        parent[rootV] = rootU
        setSize[rootU] += setSize[rootV]
        row[0] = 1
    for cell in 0 ..< 4: putI64Le(output, 32 * operation + 8 * cell, row[cell])
  int64(required)
