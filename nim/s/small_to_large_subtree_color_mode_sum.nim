const MaxN = 64
const Cells = MaxN * MaxN

proc addColor(map, color: int, amount: int64, labels: openArray[int64],
              frequencies: var array[Cells, int64], keys: var array[Cells, int],
              lengths: var array[MaxN, int], maximum: var array[MaxN, int64],
              modeSum: var array[MaxN, int64]) =
  let cell = map * MaxN + color
  let old = frequencies[cell]
  if old == 0:
    keys[map * MaxN + lengths[map]] = color
    inc lengths[map]
  if old > 0 and old == maximum[map]: modeSum[map] -= labels[color]
  let updated = old + amount
  if updated > maximum[map]:
    maximum[map] = updated
    modeSum[map] = labels[color]
  elif updated == maximum[map]:
    modeSum[map] += labels[color]
  frequencies[cell] = updated

proc putWord(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((bits shr (8 * byte)) and 255)

proc small_to_large_subtree_color_mode_sum*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "small_to_large_subtree_color_mode_sum".} =
  if input.isNil or length < 2 or length > 129: return -1
  let nv = input[0]
  if nv < 1 or nv > MaxN or length != csize_t(2 * nv): return -1
  let n = int(nv)
  var parent: array[MaxN, int]
  for vertex in 1 ..< n:
    let p = input[vertex]
    if p < 0 or p >= int64(vertex): return -1
    parent[vertex] = int(p)
  var sorted: array[MaxN, int64]
  for vertex in 0 ..< n:
    let color = input[n + vertex]
    if color < -1000 or color > 1000: return -1
    sorted[vertex] = color
  for i in 1 ..< n:
    let value = sorted[i]
    var j = i
    while j > 0 and sorted[j - 1] > value:
      sorted[j] = sorted[j - 1]
      dec j
    sorted[j] = value
  var labels: array[MaxN, int64]
  var distinct = 0
  for i in 0 ..< n:
    if distinct == 0 or labels[distinct - 1] != sorted[i]:
      labels[distinct] = sorted[i]
      inc distinct
  var colorIndex: array[MaxN, int]
  for vertex in 0 ..< n:
    var index = 0
    while labels[index] != input[n + vertex]: inc index
    colorIndex[vertex] = index
  if output.isNil or capacity < csize_t(8 * n): return -2

  var frequencies: array[Cells, int64]
  var keys: array[Cells, int]
  var lengths, mapId: array[MaxN, int]
  var maximum, modeSum, answers: array[MaxN, int64]
  for vertex in countdown(n - 1, 0):
    var largest = n
    for child in vertex + 1 ..< n:
      if parent[child] == vertex and
          (largest == n or lengths[mapId[child]] > lengths[mapId[largest]]):
        largest = child
    let map = if largest == n: vertex else: mapId[largest]
    for child in vertex + 1 ..< n:
      if parent[child] != vertex or child == largest: continue
      let small = mapId[child]
      for i in 0 ..< lengths[small]:
        let color = keys[small * MaxN + i]
        let amount = frequencies[small * MaxN + color]
        addColor(map, color, amount, labels, frequencies, keys, lengths, maximum, modeSum)
    addColor(map, colorIndex[vertex], 1, labels, frequencies, keys, lengths, maximum, modeSum)
    mapId[vertex] = map
    answers[vertex] = modeSum[map]
  for vertex in 0 ..< n: putWord(output, vertex * 8, answers[vertex])
  int64(8 * n)
