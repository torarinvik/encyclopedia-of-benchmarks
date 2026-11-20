proc minimumDigitSum(n: int64): int64 =
  var distance: array[16, int64]
  var deque: array[512, int]
  for i in 0 ..< int(n): distance[i] = 1000
  var head = 0
  var tail = 0
  var queued = 0
  let start = int(1 mod n)
  distance[start] = 1
  deque[tail] = start
  tail = (tail + 1) mod 512
  inc queued
  while queued > 0:
    let residue = deque[head]
    head = (head + 1) mod 512
    dec queued
    let zeroNext = (int64(residue) * 10) mod n
    if distance[int(zeroNext)] > distance[residue]:
      distance[int(zeroNext)] = distance[residue]
      head = (head + 511) mod 512
      deque[head] = int(zeroNext)
      inc queued
    let oneNext = (zeroNext + 1) mod n
    if distance[int(oneNext)] > distance[residue] + 1:
      distance[int(oneNext)] = distance[residue] + 1
      deque[tail] = int(oneNext)
      tail = (tail + 1) mod 512
      inc queued
  distance[0]

proc shortest_path_modulo_small_multiple*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "shortest_path_modulo_small_multiple".} =
  if input.isNil or length != 1: return -1
  let n = input[0]
  if n < 1 or n > 16: return -1
  minimumDigitSum(n)
