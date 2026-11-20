const
  MaxLength = 19
  MaxTopples = 1488

proc abelian_sandpile_stabilization*(input: ptr UncheckedArray[int64],
                                     length: csize_t): int64
    {.cdecl, exportc: "abelian_sandpile_stabilization".} =
  if input.isNil or length < 2 or length > csize_t(MaxLength): return -1
  let rowsWord = input[0]
  let colsWord = input[1]
  if rowsWord < 1 or rowsWord > 4 or colsWord < 1 or colsWord > 4: return -1
  let rows = int(rowsWord)
  let cols = int(colsWord)
  let cells = rows * cols
  if length != csize_t(2 + cells): return -1

  var board: array[16, int64]
  for site in 0 ..< cells:
    let height = input[2 + site]
    if height < 0 or height > 31: return -1
    board[site] = height

  var queue: array[16, int]
  var queued: array[16, bool]
  var head = 0
  var tail = 0
  var queueCount = 0
  for site in 0 ..< cells:
    if board[site] >= 4:
      queue[tail] = site
      tail = (tail + 1) mod cells
      inc queueCount
      queued[site] = true

  var topples = 0
  while queueCount > 0:
    let site = queue[head]
    head = (head + 1) mod cells
    dec queueCount
    queued[site] = false
    if board[site] < 4: continue
    let row = site div cols
    let col = site mod cols
    board[site] -= 4
    inc topples
    if topples > MaxTopples: return -1

    if row > 0:
      let next = site - cols
      inc board[next]
      if board[next] >= 4 and not queued[next]:
        queue[tail] = next; tail = (tail + 1) mod cells; inc queueCount; queued[next] = true
    if col + 1 < cols:
      let next = site + 1
      inc board[next]
      if board[next] >= 4 and not queued[next]:
        queue[tail] = next; tail = (tail + 1) mod cells; inc queueCount; queued[next] = true
    if row + 1 < rows:
      let next = site + cols
      inc board[next]
      if board[next] >= 4 and not queued[next]:
        queue[tail] = next; tail = (tail + 1) mod cells; inc queueCount; queued[next] = true
    if col > 0:
      let next = site - 1
      inc board[next]
      if board[next] >= 4 and not queued[next]:
        queue[tail] = next; tail = (tail + 1) mod cells; inc queueCount; queued[next] = true
    if board[site] >= 4 and not queued[site]:
      queue[tail] = site; tail = (tail + 1) mod cells; inc queueCount; queued[site] = true

  var result = 0'i64
  var place = 1'i64
  for site in 0 ..< cells:
    result += board[site] * place
    place *= 4
  result
