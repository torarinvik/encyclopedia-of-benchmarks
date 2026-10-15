const MaxLength = 1024

proc jump_game_ii*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "jump_game_ii".} =
  if values == nil or length == 0 or length > csize_t(MaxLength): return -1
  for index in 0 ..< int(length):
    if values[index] < 0 or values[index] > int64(length): return -1
  if length == 1: return 0
  var queue: array[MaxLength, csize_t]
  var distance: array[MaxLength, csize_t]
  var visited: array[MaxLength, bool]
  var head: csize_t = 0
  var tail: csize_t = 1
  queue[0] = 0
  visited[0] = true
  while head < tail:
    let cell = queue[head]
    inc head
    let farthest = cell + csize_t(values[cell])
    if farthest >= length - 1: return int64(distance[cell] + 1)
    var next = cell + 1
    while next <= farthest:
      if not visited[next]:
        visited[next] = true
        distance[next] = distance[cell] + 1
        queue[tail] = next
        inc tail
      inc next
  -1
