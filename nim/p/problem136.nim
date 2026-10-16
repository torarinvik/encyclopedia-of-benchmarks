proc problem136*(nLimit: int64): int64 {.cdecl, exportc: "problem136".} =
  if nLimit > 100_000: return -1
  if nLimit <= 0: return 0
  var solutions: array[100_000, uint8]
  let maxDelta = (nLimit + 1) div 4
  for delta in 1'i64..maxDelta:
    var y = 4 * delta - 1
    while y > delta:
      let n = y * (4 * delta - y)
      if n >= nLimit: break
      if solutions[int(n)] < 2: inc solutions[int(n)]
      dec y
  var answer = 0'i64
  for n in 0..<int(nLimit):
    if solutions[n] == 1: inc answer
  answer
