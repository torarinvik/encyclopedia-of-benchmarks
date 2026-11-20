const MaxN = 8
const MaxM = 12
const MaxInput = 111

proc putLe(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0..<8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 255)

proc hypergraph_incidence_graph_encoding*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc:"hypergraph_incidence_graph_encoding".} =
  if input.isNil or length < 2 or length > csize_t(MaxInput): return -1
  let n0 = input[0]
  let m0 = input[1]
  if n0 < 1 or n0 > 8 or m0 < 0 or m0 > 12: return -1
  let n = int(n0)
  let m = int(m0)
  var incidence: array[MaxN, array[MaxM, bool]]
  var offset = 2
  for edge in 0..<m:
    if offset >= int(length): return -1
    let size0 = input[offset]
    inc offset
    if size0 < 0 or size0 > n0 or int(size0) > int(length) - offset: return -1
    for item in 0..<int(size0):
      let vertex0 = input[offset]
      inc offset
      if vertex0 < 0 or vertex0 >= n0: return -1
      let vertex = int(vertex0)
      if incidence[vertex][edge]: return -1
      incidence[vertex][edge] = true
  if offset != int(length): return -1

  var count = 0
  for vertex in 0..<n:
    for edge in 0..<m:
      if incidence[vertex][edge]: inc count
  let nodes = n + m
  let bytes = 8 * (2 + nodes + 2 * count)
  if output.isNil or int(capacity) < bytes: return -2
  putLe(output, 0, int64(nodes))
  putLe(output, 8, int64(count))
  var word = 2
  for vertex in 0..<n:
    putLe(output, 8 * word, 0)
    inc word
  for edge in 0..<m:
    putLe(output, 8 * word, 1)
    inc word
  for vertex in 0..<n:
    for edge in 0..<m:
      if incidence[vertex][edge]:
        putLe(output, 8 * word, int64(vertex))
        inc word
        putLe(output, 8 * word, int64(n + edge))
        inc word
  int64(bytes)
