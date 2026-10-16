proc unrolled_linked_list_benchmark*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "unrolled_linked_list_benchmark".} =
  if length > 1024: return -1
  var chunks: array[512, array[5, int64]]
  var counts: array[512, int]
  var next: array[512, int]
  for i in 0 ..< 512: next[i] = 512
  var blocks = 0
  for i in 0 ..< int(length):
    let value = values[i]
    if value < -1000000 or value > 1000000: return -1
    if blocks == 0:
      blocks = 1; counts[0] = 1; chunks[0][0] = value
    elif counts[blocks - 1] < 4:
      chunks[blocks - 1][counts[blocks - 1]] = value; inc counts[blocks - 1]
    else:
      let tail = blocks - 1
      let keep = counts[tail] div 2 + 1
      let moved = counts[tail] - keep
      for j in 0 ..< moved: chunks[blocks][j] = chunks[tail][keep + j]
      counts[tail] = keep; chunks[blocks][moved] = value; counts[blocks] = moved + 1; next[tail] = blocks; inc blocks
  var checksum: int64 = 0
  var index = 0
  var b = 0
  while b < 512:
    for j in 0 ..< counts[b]:
      checksum += int64(index + 1) * (chunks[b][j] + 1000000); inc index
    if next[b] == 512: break
    b = next[b]
  checksum
