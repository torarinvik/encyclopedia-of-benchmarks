const
  MaxM = 32
  MaxN = 32
  MaxQ = 64
  Stride = MaxN + 1
  MaxInput = 3 + MaxM + MaxN + 3 * MaxQ

type
  I64Input = ptr UncheckedArray[int64]
  U8Output = ptr UncheckedArray[uint8]
  Query = object
    a, b, c: int

proc lowbit(value: int): int = value and -value

proc fenwickAdd(tree: var array[Stride + 1, int], position, count: int) =
  var index = position + 1
  while index <= count:
    inc tree[index]
    index += lowbit(index)

proc fenwickPrefix(tree: openArray[int], exclusive: int): int =
  var index = exclusive
  while index > 0:
    result += tree[index]
    index -= lowbit(index)

proc storeI64Le(output: U8Output, offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 255'u64)

proc prefix_substring_lcs*(input: I64Input, length: csize_t, output: U8Output,
    capacity: csize_t): int64 {.cdecl, exportc: "prefix_substring_lcs".} =
  if input == nil or length < 3 or length > csize_t(MaxInput): return -1
  let mValue = input[0]
  let nValue = input[1]
  let qValue = input[2]
  if mValue < 1 or mValue > MaxM or nValue < 1 or nValue > MaxN or qValue < 1 or qValue > MaxQ: return -1
  let m = int(mValue)
  let n = int(nValue)
  let q = int(qValue)
  if int(length) != 3 + m + n + 3 * q: return -1

  var s: array[MaxM, int]
  var t: array[MaxN, int]
  var offset = 3
  for i in 0 ..< m:
    let code = input[offset]
    if code < 97 or code > 122: return -1
    s[i] = int(code)
    inc offset
  for j in 0 ..< n:
    let code = input[offset]
    if code < 97 or code > 122: return -1
    t[j] = int(code)
    inc offset

  var queries: array[MaxQ, Query]
  var queryHead: array[Stride * Stride, int]
  var queryNext: array[MaxQ, int]
  for index in 0 ..< queryHead.len: queryHead[index] = -1
  for index in 0 ..< q:
    let aValue = input[offset]
    let bValue = input[offset + 1]
    let cValue = input[offset + 2]
    if aValue < 0 or aValue > mValue or bValue < 0 or bValue > cValue or cValue > nValue: return -1
    queries[index] = Query(a: int(aValue), b: int(bValue), c: int(cValue))
    let key = queries[index].a * Stride + queries[index].b
    queryNext[index] = queryHead[key]
    queryHead[key] = index
    offset += 3
  let outputBytes = 8 * q
  if output == nil or capacity < csize_t(outputBytes): return -2

  var horizontal, vertical: array[Stride * Stride, int]
  for j in 0 .. n: horizontal[j] = j
  for i in 1 .. m:
    for j in 1 .. n:
      let above = horizontal[(i - 1) * Stride + j]
      let left = vertical[i * Stride + j - 1]
      if s[i - 1] == t[j - 1]:
        horizontal[i * Stride + j] = left
        vertical[i * Stride + j] = above
      else:
        horizontal[i * Stride + j] = max(above, left)
        vertical[i * Stride + j] = min(above, left)

  var answers: array[MaxQ, int]
  for a in 0 .. m:
    var valueHead: array[Stride, int]
    var valueNext: array[Stride, int]
    for value in 0 .. n: valueHead[value] = -1
    for position in 0 .. n:
      let value = horizontal[a * Stride + position]
      valueNext[position] = valueHead[value]
      valueHead[value] = position
    var fenwick: array[Stride + 1, int]
    for b in 0 .. n:
      var position = valueHead[b]
      while position >= 0:
        fenwickAdd(fenwick, position, n + 1)
        position = valueNext[position]
      var queryIndex = queryHead[a * Stride + b]
      while queryIndex >= 0:
        let query = queries[queryIndex]
        answers[queryIndex] = fenwickPrefix(fenwick, query.c + 1) - fenwickPrefix(fenwick, query.b + 1)
        queryIndex = queryNext[queryIndex]
  for index in 0 ..< q: storeI64Le(output, 8 * index, int64(answers[index]))
  int64(outputBytes)
