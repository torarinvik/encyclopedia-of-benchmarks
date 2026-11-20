## Uncompiled suffix-automaton minimum-rotation draft.
proc suffix_automaton_minimum_rotation*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "suffix_automaton_minimum_rotation".} =
  if input == nil or length < 2 or length > 258: return -1
  let rawN = input[0]
  if rawN < 1 or rawN > 256 or length != csize_t(rawN+1): return -1
  let n = int(rawN)
  for i in 1 ..< int(length):
    if input[i] < 0 or input[i] > 255: return -1
  if output == nil or capacity < csize_t(n): return -2
  var transitions: array[262144, int32]
  var links, lengths: array[1024, int32]
  for i in 0 ..< transitions.len: transitions[i] = -1
  for i in 0 ..< links.len: links[i] = -1
  var count = 1
  var last = 0
  for i in 0 ..< 2*n:
    let symbol = int(input[1+i mod n])
    let current = count
    inc count
    lengths[current] = lengths[last]+1
    var p = last
    while p >= 0 and transitions[p*256+symbol] < 0:
      transitions[p*256+symbol] = int32(current)
      p = int(links[p])
    if p < 0: links[current] = 0
    else:
      let q = int(transitions[p*256+symbol])
      if lengths[p]+1 == lengths[q]: links[current] = int32(q)
      else:
        let clone = count
        inc count
        for c in 0 ..< 256: transitions[clone*256+c] = transitions[q*256+c]
        links[clone] = links[q]
        lengths[clone] = lengths[p]+1
        while p >= 0 and transitions[p*256+symbol] == int32(q):
          transitions[p*256+symbol] = int32(clone)
          p = int(links[p])
        links[q] = int32(clone)
        links[current] = int32(clone)
    last = current
  var state = 0
  for i in 0 ..< n:
    var symbol = 0
    while transitions[state*256+symbol] < 0: inc symbol
    output[i] = uint8(symbol)
    state = int(transitions[state*256+symbol])
  rawN
