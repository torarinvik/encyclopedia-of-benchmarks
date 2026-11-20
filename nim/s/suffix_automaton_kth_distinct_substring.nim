## Independently authored draft; not compiled or run.
proc suffix_automaton_kth_distinct_substring*(input: ptr UncheckedArray[int64],
    length: csize_t, output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "suffix_automaton_kth_distinct_substring".} =
  if input == nil or length < 3 or length > 259: return -1
  let rawN = input[0]
  var k = input[1]
  if rawN < 1 or rawN > 256 or length != csize_t(rawN + 2) or k < 1: return -1
  let n = int(rawN)
  for i in 0 ..< n:
    if input[i + 2] < 0 or input[i + 2] > 255: return -1
  var transitions: array[131072, int32]
  var links, lengths: array[512, int32]
  var paths: array[512, int64]
  for i in 0 ..< transitions.len: transitions[i] = -1
  for i in 0 ..< links.len: links[i] = -1
  var count = 1
  var last = 0
  for i in 0 ..< n:
    let symbol = int(input[i + 2])
    let current = count
    inc count
    lengths[current] = lengths[last] + 1
    var p = last
    while p >= 0 and transitions[p * 256 + symbol] < 0:
      transitions[p * 256 + symbol] = int32(current)
      p = int(links[p])
    if p < 0: links[current] = 0
    else:
      let q = int(transitions[p * 256 + symbol])
      if lengths[p] + 1 == lengths[q]: links[current] = int32(q)
      else:
        let clone = count
        inc count
        for c in 0 ..< 256: transitions[clone * 256 + c] = transitions[q * 256 + c]
        links[clone] = links[q]
        lengths[clone] = lengths[p] + 1
        while p >= 0 and transitions[p * 256 + symbol] == int32(q):
          transitions[p * 256 + symbol] = int32(clone)
          p = int(links[p])
        links[q] = int32(clone)
        links[current] = int32(clone)
    last = current
  var buckets: array[257, int]
  var order: array[512, int]
  for i in 0 ..< count: inc buckets[int(lengths[i])]
  for i in 1 .. n: buckets[i] += buckets[i - 1]
  for i in countdown(count - 1, 0):
    let l = int(lengths[i])
    dec buckets[l]
    order[buckets[l]] = i
  for i in countdown(count - 1, 0):
    let state = order[i]
    for c in 0 ..< 256:
      let next = int(transitions[state * 256 + c])
      if next >= 0: paths[state] += 1 + paths[next]
  if k > paths[0]: return -1
  var resultBytes: array[256, uint8]
  var used = 0
  var state = 0
  while true:
    var found = false
    for c in 0 ..< 256:
      let next = int(transitions[state * 256 + c])
      if next < 0: continue
      let group = 1 + paths[next]
      if k > group:
        k -= group
      else:
        resultBytes[used] = uint8(c)
        inc used
        state = next
        found = true
        break
    if not found: return -1
    if k == 1: break
    dec k
  if output == nil or capacity < csize_t(used): return -2
  for i in 0 ..< used: output[i] = resultBytes[i]
  int64(used)
