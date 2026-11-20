const MaxText = 256
const MaxPattern = 16
const MaxInput = 274

proc optimal_mismatch*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "optimal_mismatch".} =
  if values == nil or length < 2 or length > csize_t(MaxInput): return -2
  let rawN = values[0]
  let rawM = values[1]
  if rawN < 0 or rawN > int64(MaxText) or rawM < 1 or rawM > int64(MaxPattern): return -2
  let n = int(rawN)
  let m = int(rawM)
  if length != csize_t(2 + n + m): return -2
  let patternStart = 2 + n
  for i in 0 ..< n + m:
    if values[2 + i] < 0 or values[2 + i] > 127: return -2
  if m > n: return -1

  var frequency: array[128, int]
  for i in 0 ..< n:
    inc frequency[int(values[2 + i])]
  var order: array[16, int]
  for i in 0 ..< m:
    order[i] = i
  for i in 1 ..< m:
    let selected = order[i]
    var cursor = i
    while cursor > 0:
      let previous = order[cursor - 1]
      let pf = frequency[int(values[patternStart + previous])]
      let sf = frequency[int(values[patternStart + selected])]
      if pf < sf or (pf == sf and previous > selected): break
      order[cursor] = previous
      dec cursor
    order[cursor] = selected

  var quickShift: array[128, int]
  for byte in 0 ..< 128: quickShift[byte] = m + 1
  for i in 0 ..< m:
    quickShift[int(values[patternStart + i])] = m - i

  var adaptedShift: array[16, int]
  for rank in 0 ..< m:
    adaptedShift[rank] = m
    let mismatch = order[rank]
    for shift in 1 .. m:
      var compatible = true
      for prior in 0 ..< rank:
        let position = order[prior]
        if position >= shift and values[patternStart + position] != values[patternStart + position - shift]:
          compatible = false
          break
      if not compatible: continue
      if mismatch >= shift and values[patternStart + mismatch - shift] == values[patternStart + mismatch]:
        continue
      adaptedShift[rank] = shift
      break

  var start = 0
  let lastStart = n - m
  while start <= lastStart:
    var rank = 0
    while rank < m and values[2 + start + order[rank]] == values[patternStart + order[rank]]:
      inc rank
    if rank == m: return int64(start)
    if start + m == n: break
    let quick = quickShift[int(values[2 + start + m])]
    start += max(adaptedShift[rank], quick)
  -1
