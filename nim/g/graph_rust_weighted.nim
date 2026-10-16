const MaxVertices = 64
const MaxEdges = 256

proc putI64(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 255)

proc graph_rust_weighted*(input: ptr UncheckedArray[int64], length: csize_t,
                          output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc: "graph_rust_weighted".} =
  if input.isNil or length < 2: return -1
  let nValue = input[0]
  let mValue = input[1]
  if nValue < 0 or nValue > MaxVertices or mValue < 0 or mValue > MaxEdges: return -1
  let n = int(nValue)
  let m = int(mValue)
  if int(length) != 2 + 3 * m: return -1
  for edge in 0 ..< m:
    let u = input[2 + 3 * edge]
    let v = input[3 + 3 * edge]
    let weight = input[4 + 3 * edge]
    if u < 0 or u >= nValue or v < 0 or v >= nValue: return -1
    if weight < -2147483648'i64 or weight > 2147483647'i64: return -1
  let required = (1 + n + 4 * m) * 8
  if output.isNil or int(capacity) < required: return -2
  var cursor = 0
  putI64(output, cursor * 8, nValue)
  inc cursor
  for vertex in 0 ..< n:
    var degree = 0
    for edge in 0 ..< m:
      if input[2 + 3 * edge] == int64(vertex): inc degree
      if input[3 + 3 * edge] == int64(vertex): inc degree
    putI64(output, cursor * 8, int64(degree))
    inc cursor
    for edge in 0 ..< m:
      let u = input[2 + 3 * edge]
      let v = input[3 + 3 * edge]
      let weight = input[4 + 3 * edge]
      if u == int64(vertex):
        putI64(output, cursor * 8, v)
        inc cursor
        putI64(output, cursor * 8, weight)
        inc cursor
      if v == int64(vertex):
        putI64(output, cursor * 8, u)
        inc cursor
        putI64(output, cursor * 8, weight)
        inc cursor
  int64(required)
