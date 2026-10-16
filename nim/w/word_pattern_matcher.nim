proc matchAt(input: ptr UncheckedArray[int64], patternStart, textStart, plen, tlen, pi, ti: int,
             starts, lengths: var array[95, int]): bool =
  if pi == plen: return ti == tlen
  let symbol = int(input[patternStart + pi] - 32)
  if lengths[symbol] >= 0:
    let size = lengths[symbol]
    if ti + size > tlen: return false
    for j in 0 ..< size:
      if input[textStart + ti + j] != input[textStart + starts[symbol] + j]: return false
    return matchAt(input, patternStart, textStart, plen, tlen, pi + 1, ti + size, starts, lengths)
  if ti >= tlen: return false
  for size in 1 .. (tlen - ti):
    var used = false
    for other in 0 ..< 95:
      if lengths[other] == size:
        var same = true
        for j in 0 ..< size:
          if input[textStart + ti + j] != input[textStart + starts[other] + j]: same = false; break
        if same: used = true; break
    if used: continue
    starts[symbol] = ti; lengths[symbol] = size
    if matchAt(input, patternStart, textStart, plen, tlen, pi + 1, ti + size, starts, lengths): return true
    lengths[symbol] = -1
  false

proc word_pattern_matcher*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc: "word_pattern_matcher".} =
  discard output; discard capacity
  if input.isNil or length < 2 or input[0] < 0 or input[0] > 8: return -1
  let plen = int(input[0])
  if length < csize_t(plen + 2): return -1
  let textIndex = plen + 1
  if input[textIndex] < 0 or input[textIndex] > 32: return -1
  let tlen = int(input[textIndex])
  if length != csize_t(textIndex + 1 + tlen): return -1
  for i in 0 ..< plen:
    if input[i + 1] < 32 or input[i + 1] > 126: return -1
  for i in 0 ..< tlen:
    if input[textIndex + 1 + i] < 32 or input[textIndex + 1 + i] > 126: return -1
  var starts: array[95, int]
  var sizes: array[95, int]
  for i in 0 ..< 95: starts[i] = -1; sizes[i] = -1
  if matchAt(input, 1, textIndex + 1, plen, tlen, 0, 0, starts, sizes): 1 else: 0
