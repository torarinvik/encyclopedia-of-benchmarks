const MaxN = 6
const MaxInput = 32
const MaxOutput = 64

proc put(output: ptr UncheckedArray[uint8], index: int, value: uint64) =
  for byte in 0..<8: output[index * 8 + byte] = uint8((value shr (byte * 8)) and 255)

proc chordal_graph_recognition*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc: "chordal_graph_recognition".} =
  if input.isNil or length < 2 or length > csize_t(MaxInput): return -1
  let n64, m64 = input[0], input[1]
  if n64 < 1 or n64 > MaxN or m64 < 0 or m64 > 15: return -1
  let n, m = int(n64), int(m64)
  if m > n * (n - 1) div 2 or int(length) != 2 + 2 * m: return -1
  var adjacent: array[MaxN * MaxN, bool]
  for edge in 0..<m:
    let a64, b64 = input[2 + 2 * edge], input[3 + 2 * edge]
    if a64 < 0 or b64 < 0 or a64 >= n64 or b64 >= n64 or a64 == b64: return -1
    let a, b = int(a64), int(b64)
    if adjacent[a * MaxN + b]: return -1
    adjacent[a * MaxN + b] = true
    adjacent[b * MaxN + a] = true
  var selected: array[MaxN, bool]
  var label, reverseOrder, order, position: array[MaxN, int]
  for step in 0..<n:
    var chosen = -1
    for v in 0..<n:
      if not selected[v] and (chosen < 0 or label[v] > label[chosen]): chosen = v
    selected[chosen] = true
    reverseOrder[step] = chosen
    for u in 0..<n:
      if not selected[u] and adjacent[chosen * MaxN + u]: inc label[u]
  for i in 0..<n:
    order[i] = reverseOrder[n - i - 1]
    position[order[i]] = i
  var peo = true
  for i in 0..<n:
    let v = order[i]
    var parent = -1
    for u in 0..<n:
      if adjacent[v * MaxN + u] and position[u] > i and (parent < 0 or position[u] < position[parent]): parent = u
    if parent >= 0:
      for u in 0..<n:
        if adjacent[v * MaxN + u] and position[u] > i and u != parent and not adjacent[parent * MaxN + u]: peo = false
  var packed: array[8, uint64]
  var count = 0
  if peo:
    packed[count] = 1; inc count
    for i in 0..<n: packed[count] = uint64(order[i]); inc count
  else:
    var found = false
    var cycle: array[MaxN, int]
    var cycleLength = 0
    for mask in 0..<(1 shl n):
      var vertices: array[MaxN, int]
      var size = 0
      for v in 0..<n:
        if (mask and (1 shl v)) != 0: vertices[size] = v; inc size
      if size < 4: continue
      var valid = true
      for i in 0..<size:
        var degree = 0
        for j in 0..<size:
          if adjacent[vertices[i] * MaxN + vertices[j]]: inc degree
        if degree != 2: valid = false
      if not valid: continue
      var seen: array[MaxN, bool]
      var queue: array[MaxN, int]
      var head = 0
      var tail = 1
      seen[vertices[0]] = true; queue[0] = vertices[0]
      while head < tail:
        let v = queue[head]; inc head
        for j in 0..<size:
          let u = vertices[j]
          if adjacent[v * MaxN + u] and not seen[u]: seen[u] = true; queue[tail] = u; inc tail
      if tail != size: continue
      cycleLength = size
      let start = vertices[0]
      var previous = start
      var current = start
      for j in 0..<size:
        if adjacent[start * MaxN + vertices[j]]: current = vertices[j]; break
      cycle[0] = start
      for i in 1..<size:
        cycle[i] = current
        var next = start
        for j in 0..<size:
          let u = vertices[j]
          if adjacent[current * MaxN + u] and u != previous: next = u; break
        previous = current; current = next
      found = true
      break
    if not found: return -1
    packed[count] = 0; inc count
    packed[count] = uint64(cycleLength); inc count
    for i in 0..<cycleLength: packed[count] = uint64(cycle[i]); inc count
  let bytes = count * 8
  if output.isNil or capacity < csize_t(bytes): return -2
  var staged: array[MaxOutput, uint8]
  for i in 0..<count: put(addr staged[0], i, packed[i])
  for i in 0..<bytes: output[i] = staged[i]
  int64(bytes)
