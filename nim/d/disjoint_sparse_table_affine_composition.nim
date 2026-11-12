const
  Modulus = 1_000_000_007'i64
  MaxN = 32
  MaxQ = 32
  MaxLevels = 5

type Affine = object
  a, b: int64

proc combine(left, right: Affine): Affine =
  Affine(a: (right.a * left.a) mod Modulus,
         b: (right.a * left.b + right.b) mod Modulus)

proc putWord(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 255)

proc disjoint_sparse_table_affine_composition*(input: ptr UncheckedArray[int64],
    length: csize_t, output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "disjoint_sparse_table_affine_composition".} =
  if input.isNil or length < 2 or length > csize_t(130): return -1
  let nValue = input[0]
  let qValue = input[1]
  if nValue < 1 or nValue > MaxN or qValue < 1 or qValue > MaxQ: return -1
  let n = int(nValue)
  let q = int(qValue)
  if int(length) != 2 + 2 * n + 2 * q: return -1

  var maps: array[MaxN, Affine]
  var left, right: array[MaxQ, int]
  var cursor = 2
  for index in 0 ..< n:
    let a = input[cursor]
    let b = input[cursor + 1]
    cursor += 2
    if a < 0 or a >= Modulus or b < 0 or b >= Modulus: return -1
    maps[index] = Affine(a: a, b: b)
  for query in 0 ..< q:
    let lo = input[cursor]
    let hi = input[cursor + 1]
    cursor += 2
    if lo < 0 or lo > hi or hi >= nValue: return -1
    left[query] = int(lo)
    right[query] = int(hi)

  let outputBytes = q * 16
  if output.isNil or capacity < csize_t(outputBytes): return -2

  var table: array[MaxLevels, array[MaxN, Affine]]
  var levels = 0
  var span = 1
  while span < n:
    inc levels
    span *= 2
  for level in 0 ..< levels:
    let half = 1 shl level
    let width = half * 2
    var start = 0
    while start < n:
      let middle = min(start + half, n)
      let ending = min(start + width, n)
      if middle > start:
        table[level][middle - 1] = maps[middle - 1]
        var index = middle - 1
        while index > start:
          table[level][index - 1] = combine(maps[index - 1], table[level][index])
          dec index
      if middle < ending:
        table[level][middle] = maps[middle]
        var index = middle + 1
        while index < ending:
          table[level][index] = combine(table[level][index - 1], maps[index])
          inc index
      start += width

  for query in 0 ..< q:
    var answer: Affine
    if left[query] == right[query]:
      answer = maps[left[query]]
    else:
      var difference = left[query] xor right[query]
      var level = 0
      while difference > 1:
        difference = difference shr 1
        inc level
      answer = combine(table[level][left[query]], table[level][right[query]])
    putWord(output, query * 16, answer.a)
    putWord(output, query * 16 + 8, answer.b)
  int64(outputBytes)
