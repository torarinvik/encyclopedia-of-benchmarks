proc shortest_absent_substring_sam*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "shortest_absent_substring_sam".} =
  if input.isNil or length < 2 or length > 66: return -1
  if input[0] < 2 or input[0] > 4 or input[1] < 0 or input[1] > 64: return -1
  let alphabet = int(input[0])
  let n = int(input[1])
  if length != csize_t(2+n): return -1
  for i in 0..<n:
    if input[2+i] < 0 or input[2+i] >= int64(alphabet): return -1
  var edges: array[129, array[4, int]]
  var links, lens: array[129, int]
  for s in 0..<129:
    links[s] = -1
    for a in 0..<4: edges[s][a] = -1
  var size = 1
  var last = 0
  for i in 0..<n:
    let symbol = int(input[2+i])
    let current = size
    inc size
    lens[current] = lens[last]+1
    var p = last
    while p >= 0 and edges[p][symbol] < 0:
      edges[p][symbol] = current
      p = links[p]
    if p < 0: links[current] = 0
    else:
      let q = edges[p][symbol]
      if lens[p]+1 == lens[q]: links[current] = q
      else:
        let clone = size
        inc size
        edges[clone] = edges[q]
        links[clone] = links[q]
        lens[clone] = lens[p]+1
        while p >= 0 and edges[p][symbol] == q:
          edges[p][symbol] = clone
          p = links[p]
        links[q] = clone
        links[current] = clone
    last = current
  var counts: array[65, int]
  var order, dp: array[129, int]
  for s in 0..<size: inc counts[lens[s]]
  for i in 1..n: counts[i] += counts[i-1]
  for s in countdown(size-1, 0):
    dec counts[lens[s]]
    order[counts[lens[s]]] = s
  for i in countdown(size-1, 0):
    let s = order[i]
    var best = 100
    for a in 0..<alphabet:
      let child = edges[s][a]
      let candidate = if child < 0: 1 else: 1+dp[child]
      best = min(best, candidate)
    dp[s] = best
  var result: array[6, uint8]
  var count = 0
  var state = 0
  while state >= 0:
    for a in 0..<alphabet:
      let child = edges[state][a]
      if (child < 0 and dp[state] == 1) or (child >= 0 and dp[state] == 1+dp[child]):
        result[count] = uint8(a)
        inc count
        state = child
        break
  if output.isNil or capacity < csize_t(count): return -2
  for i in 0..<count: output[i] = result[i]
  int64(count)
