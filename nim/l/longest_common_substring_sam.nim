proc longest_common_substring_sam*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "longest_common_substring_sam".} =
  if input.isNil or length < 2 or length > 515: return -1
  if input[0] < 0 or input[0] > 256: return -1
  let n = int(input[0])
  if length < csize_t(n+2) or input[n+1] < 0 or input[n+1] > 256: return -1
  let m = int(input[n+1])
  if length != csize_t(n+m+2): return -1
  for i in 0..<n:
    if input[1+i] < 32 or input[1+i] > 126: return -1
  for i in 0..<m:
    if input[n+2+i] < 32 or input[n+2+i] > 126: return -1
  var edges: array[513, array[95, int32]]
  var links: array[513, int32]
  var lens: array[513, int]
  for s in 0..<513:
    links[s] = -1
    for a in 0..<95: edges[s][a] = -1
  var size = 1
  var last = 0
  for i in 0..<n:
    let symbol = int(input[1+i])-32
    let current = size
    inc size
    lens[current] = lens[last]+1
    var p = last
    while p >= 0 and edges[p][symbol] < 0:
      edges[p][symbol] = int32(current)
      p = int(links[p])
    if p < 0: links[current] = 0
    else:
      let q = int(edges[p][symbol])
      if lens[p]+1 == lens[q]: links[current] = int32(q)
      else:
        let clone = size
        inc size
        edges[clone] = edges[q]; links[clone] = links[q]; lens[clone] = lens[p]+1
        while p >= 0 and edges[p][symbol] == int32(q):
          edges[p][symbol] = int32(clone)
          p = int(links[p])
        links[q] = int32(clone); links[current] = int32(clone)
    last = current
  var state = 0
  var matched = 0
  var best = 0
  for i in 0..<m:
    let symbol = int(input[n+2+i])-32
    while state != 0 and edges[state][symbol] < 0:
      state = int(links[state])
      matched = lens[state]
    let next = int(edges[state][symbol])
    if next < 0:
      state = 0
      matched = 0
    else:
      state = next
      inc matched
      best = max(best, matched)
  int64(best)
