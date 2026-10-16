const MaxLits = 80

proc visitOrder(graph: ptr UncheckedArray[uint8], n, v: int, seen: ptr UncheckedArray[uint8], order: ptr UncheckedArray[int], count: var int) =
  seen[v] = 1
  for w in 0 ..< n:
    if graph[v * MaxLits + w] != 0 and seen[w] == 0: visitOrder(graph, n, w, seen, order, count)
  order[count] = v; inc count

proc visitComponent(graph: ptr UncheckedArray[uint8], n, v: int, comp: ptr UncheckedArray[int], id: int) =
  comp[v] = id
  for w in 0 ..< n:
    if graph[v * MaxLits + w] != 0 and comp[w] < 0: visitComponent(graph, n, w, comp, id)

proc two_sat*(input: ptr UncheckedArray[int64], length: csize_t, output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc: "two_sat".} =
  if input.isNil or length < 2 or length > 4096: return -1
  if input[0] < 0 or input[0] > 40 or input[1] < 0 or input[1] > 2047: return -1
  let variables = int(input[0]); let clauses = int(input[1])
  if length != csize_t(2 + 2 * clauses): return -1
  let n = variables * 2
  var graph: array[6400, uint8]; var transpose: array[6400, uint8]
  for i in 0 ..< clauses:
    let a = input[2 + 2*i]; let b = input[3 + 2*i]
    if a == 0 or b == 0 or abs(a) > input[0] or abs(b) > input[0]: return -1
    let x = 2 * (int(abs(a)) - 1) + (if a < 0: 1 else: 0)
    let y = 2 * (int(abs(b)) - 1) + (if b < 0: 1 else: 0)
    graph[(x xor 1) * MaxLits + y] = 1; transpose[y * MaxLits + (x xor 1)] = 1
    graph[(y xor 1) * MaxLits + x] = 1; transpose[x * MaxLits + (y xor 1)] = 1
  var seen: array[80, uint8]; var order: array[80, int]; var count = 0
  for v in 0 ..< n:
    if seen[v] == 0: visitOrder(cast[ptr UncheckedArray[uint8]](addr graph[0]), n, v, cast[ptr UncheckedArray[uint8]](addr seen[0]), cast[ptr UncheckedArray[int]](addr order[0]), count)
  var comp: array[80, int]
  for i in 0 ..< n: comp[i] = -1
  var id = 0
  while count > 0:
    dec count; let v = order[count]
    if comp[v] < 0: visitComponent(cast[ptr UncheckedArray[uint8]](addr transpose[0]), n, v, cast[ptr UncheckedArray[int]](addr comp[0]), id); inc id
  var sat = true
  for i in 0 ..< variables:
    if comp[2*i] == comp[2*i+1]: sat = false
  let outlen = if sat: variables + 1 else: 1
  if output.isNil or capacity < csize_t(outlen): return -2
  output[0] = uint8(ord(sat))
  if sat:
    for i in 0 ..< variables: output[i+1] = uint8(ord(comp[2*i] > comp[2*i+1]))
  int64(outlen)
