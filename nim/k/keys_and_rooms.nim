## Return whether every room is reachable from room zero.
const MaxRooms = 1000
const MaxInputLength = 100001

proc keys_and_rooms*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "keys_and_rooms".} =
  if values.isNil or length < 3 or length > csize_t(MaxInputLength): return -1
  if values[0] < 2 or values[0] > MaxRooms: return -1
  let roomCount = int(values[0])
  var starts: array[MaxRooms, int]
  var degrees: array[MaxRooms, int]
  var cursor = 1

  for room in 0 ..< roomCount:
    if cursor >= int(length): return -1
    let countValue = values[cursor]
    inc cursor
    if countValue < 0 or countValue > int64(roomCount): return -1
    let degree = int(countValue)
    if degree > int(length) - cursor: return -1
    starts[room] = cursor
    degrees[room] = degree
    for edge in 0 ..< degree:
      let key = values[cursor + edge]
      if key < 0 or key >= int64(roomCount): return -1
    cursor += degree
  if cursor != int(length): return -1

  var visited: array[MaxRooms, bool]
  var stack: array[MaxRooms, int]
  var stackSize = 1
  var reached = 0
  stack[0] = 0
  visited[0] = true
  while stackSize > 0:
    dec stackSize
    let room = stack[stackSize]
    inc reached
    for edge in 0 ..< degrees[room]:
      let key = int(values[starts[room] + edge])
      if not visited[key]:
        visited[key] = true
        stack[stackSize] = key
        inc stackSize
  if reached == roomCount: 1 else: 0
