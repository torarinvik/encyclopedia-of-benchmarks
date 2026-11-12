const MaxN = 32
const MaxM = 64
const MaxInput = 131
const MaxOutput = 1592

proc putI64(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0..<8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 255)

proc tree_decomposition_width_2*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "tree_decomposition_width_2".} =
  if input.isNil or length < 2 or length > csize_t(MaxInput): return -1
  let n64 = input[0]
  let m64 = input[1]
  if n64 < 1 or n64 > MaxN or m64 < 0 or m64 > MaxM: return -1
  let n = int(n64)
  let m = int(m64)
  if m > n * (n - 1) div 2 or int(length) != 2 + 2 * m: return -1

  var adjacent: array[MaxN * MaxN, bool]
  for edge in 0..<m:
    let left64 = input[2 + 2 * edge]
    let right64 = input[3 + 2 * edge]
    if left64 < 0 or left64 >= right64 or right64 >= n64: return -1
    let left = int(left64)
    let right = int(right64)
    if adjacent[left * MaxN + right]: return -1
    adjacent[left * MaxN + right] = true
    adjacent[right * MaxN + left] = true

  var active: array[MaxN, bool]
  var order: array[MaxN, int]
  var bags: array[MaxN * 3, int64]
  var bagSizes: array[MaxN, int]
  var later: array[MaxN * 2, int]
  var laterCounts: array[MaxN, int]
  var position: array[MaxN, int]
  for vertex in 0..<n: active[vertex] = true

  for step in 0..<n:
    var chosen = -1
    var neighbors: array[2, int]
    var count = 0
    for vertex in 0..<n:
      if not active[vertex]: continue
      var degree = 0
      for other in 0..<n:
        if active[other] and adjacent[vertex * MaxN + other]: inc degree
      if degree <= 2:
        chosen = vertex
        for other in 0..<n:
          if active[other] and adjacent[vertex * MaxN + other]:
            neighbors[count] = other
            inc count
        break
    if chosen < 0: return -1
    order[step] = chosen
    laterCounts[step] = count
    bagSizes[step] = count + 1
    bags[step * 3] = int64(chosen)
    for index in 0..<count:
      later[step * 2 + index] = neighbors[index]
      bags[step * 3 + index + 1] = int64(neighbors[index])
    for i in 0..count:
      for j in (i + 1)..<count + 1:
        if bags[step * 3 + j] < bags[step * 3 + i]:
          swap(bags[step * 3 + i], bags[step * 3 + j])
    if count == 2:
      adjacent[neighbors[0] * MaxN + neighbors[1]] = true
      adjacent[neighbors[1] * MaxN + neighbors[0]] = true
    active[chosen] = false

  for step in 0..<n: position[order[step]] = step
  var parents: array[MaxN, int]
  for step in 0..<n:
    parents[step] = n
    if laterCounts[step] > 0:
      var selected = later[step * 2]
      if laterCounts[step] == 2 and position[later[step * 2 + 1]] < position[selected]:
        selected = later[step * 2 + 1]
      parents[step] = position[selected]

  let bytes = 8 * (6 * n + 7)
  if output.isNil or capacity < csize_t(bytes) or bytes > MaxOutput: return -2
  var staged: array[MaxOutput, uint8]
  putI64(addr staged[0], 0, int64(n + 1))
  putI64(addr staged[0], 8, 2)
  putI64(addr staged[0], 16, int64(n))
  var cursor = 24
  for bag in 0..n:
    let count = if bag == n: 0 else: bagSizes[bag]
    putI64(addr staged[0], cursor, int64(count))
    cursor += 8
    for slot in 0..<3:
      let value = if slot < count: bags[bag * 3 + slot] else: -1'i64
      putI64(addr staged[0], cursor, value)
      cursor += 8
  for child in 0..<n:
    putI64(addr staged[0], cursor, int64(child))
    putI64(addr staged[0], cursor + 8, int64(parents[child]))
    cursor += 16
  for byte in 0..<bytes: output[byte] = staged[byte]
  int64(bytes)
