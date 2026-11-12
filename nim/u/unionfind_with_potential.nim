const
  MaxN = 64
  MaxQ = 256
  Modulus = 998_244_353'i64

proc normalize(valueInput: int64): int64 =
  result = valueInput mod Modulus
  if result < 0: result += Modulus

proc findRoot(parent: var array[MaxN, int], difference: var array[MaxN, int64], item: int): int =
  if parent[item] != item:
    let oldParent = parent[item]
    let root = findRoot(parent, difference, oldParent)
    difference[item] = normalize(difference[item] + difference[oldParent])
    parent[item] = root
  parent[item]

proc putI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8: output[offset + byte] = uint8((bits shr (8 * byte)) and 255)

proc unionfind_with_potential*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc: "unionfind_with_potential".} =
  if input.isNil or length < csize_t(6) or length > csize_t(2 + 4 * MaxQ): return -1
  let n64 = input[0]
  let q64 = input[1]
  if n64 < 1 or n64 > int64(MaxN) or q64 < 1 or q64 > int64(MaxQ): return -1
  let n = int(n64)
  let q = int(q64)
  if int(length) != 2 + 4 * q: return -1

  for operation in 0 ..< q:
    let position = 2 + 4 * operation
    let kind = input[position]
    let u = input[position + 1]
    let v = input[position + 2]
    let x = input[position + 3]
    if u < 0 or u >= n64 or v < 0 or v >= n64: return -1
    if kind == 0:
      if x < 0 or x >= Modulus: return -1
    elif kind == 1:
      if x != 0: return -1
    else:
      return -1
  let required = 8 * q
  if output.isNil or capacity < csize_t(required): return -2

  var parent: array[MaxN, int]
  var setSize: array[MaxN, int]
  var difference: array[MaxN, int64]
  for item in 0 ..< n:
    parent[item] = item
    setSize[item] = 1
  for operation in 0 ..< q:
    let position = 2 + 4 * operation
    let kind = input[position]
    let u = int(input[position + 1])
    let v = int(input[position + 2])
    let x = input[position + 3]
    let rootU = findRoot(parent, difference, u)
    let rootV = findRoot(parent, difference, v)
    var answer: int64
    if kind == 1:
      answer = if rootU == rootV: normalize(difference[u] - difference[v]) else: -1
    elif rootU == rootV:
      answer = int64(normalize(difference[u] - difference[v]) == x)
    elif setSize[rootU] < setSize[rootV]:
      parent[rootU] = rootV
      difference[rootU] = normalize(x - difference[u] + difference[v])
      setSize[rootV] += setSize[rootU]
      answer = 1
    else:
      parent[rootV] = rootU
      difference[rootV] = normalize(difference[u] - difference[v] - x)
      setSize[rootU] += setSize[rootV]
      answer = 1
    putI64Le(output, 8 * operation, answer)
  int64(required)
