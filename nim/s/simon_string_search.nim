type
  I64Input = ptr UncheckedArray[int64]

proc simon_string_search*(values: I64Input, length: csize_t): int64
    {.cdecl, exportc: "simon_string_search".} =
  if values.isNil or length < 2 or length > 274: return -2
  if values[0] < 0 or values[0] > 256 or values[1] < 1 or values[1] > 16: return -2
  let n = int(values[0])
  let m = int(values[1])
  if length != csize_t(2 + n + m): return -2
  for i in 0 ..< n + m:
    if values[2 + i] < 0 or values[2 + i] > 15: return -2
  let p = 2 + n
  var head: array[16, int]
  var edgeTarget: array[16, int]
  var edgeNext: array[16, int]
  for i in 0 ..< 16: head[i] = -1
  var edgeCount = 0
  var ell = -1
  for i in 1 ..< m:
    let k = ell
    var cell = if k < 0: -1 else: head[k]
    ell = -1
    if values[p + i] == values[p + k + 1]:
      ell = k + 1
    else:
      edgeTarget[edgeCount] = k + 1
      edgeNext[edgeCount] = head[i - 1]
      head[i - 1] = edgeCount
      inc edgeCount
    while cell >= 0:
      let q = edgeTarget[cell]
      if values[p + i] == values[p + q]:
        ell = q
      else:
        edgeTarget[edgeCount] = q
        edgeNext[edgeCount] = head[i - 1]
        head[i - 1] = edgeCount
        inc edgeCount
      cell = edgeNext[cell]
  var state = -1
  var matches = 0'i64
  for j in 0 ..< n:
    let symbol = values[2 + j]
    if state < m - 1 and values[p + state + 1] == symbol:
      inc state
    elif state >= 0:
      var edge = head[state]
      state = -1
      while edge >= 0:
        let q = edgeTarget[edge]
        if values[p + q] == symbol:
          state = q
          break
        edge = edgeNext[edge]
    if state >= m - 1:
      inc matches
      state = ell
  matches
