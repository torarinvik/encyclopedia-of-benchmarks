proc multisetCount(n, r: int): int =
  if r == 0: return 1
  if n == 0: return 0
  let top = n + r - 1
  var result = 1
  for index in 1 .. r:
    result = result * (top - r + index) div index
  result

proc combinations_with_repetition_lexicographic*(input: ptr UncheckedArray[int64],
    length: csize_t, output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc.} =
  if input.isNil or length != 2: return -1
  let nWord = input[0]
  let rWord = input[1]
  if nWord < 0 or nWord > 4 or rWord < 0 or rWord > 4: return -1
  let n = int(nWord)
  let r = int(rWord)
  let count = multisetCount(n, r)
  let byteCount = 2 + count * r
  if output.isNil or capacity < csize_t(byteCount): return -2

  output[0] = uint8(count and 255)
  output[1] = uint8((count shr 8) and 255)
  var current: array[4, uint8]
  for ordinal in 0 ..< count:
    for position in 0 ..< r:
      output[2 + ordinal * r + position] = current[position]
    if ordinal + 1 < count and r > 0:
      var position = r
      while int(current[position - 1]) == n - 1: dec position
      dec position
      inc current[position]
      for suffix in (position + 1) ..< r: current[suffix] = current[position]
  int64(byteCount)
