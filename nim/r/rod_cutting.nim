## Bottom-up dynamic programming for the bounded rod-cutting problem.

proc rod_cutting*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "rod_cutting".} =
  if values == nil or length < 2: return -1
  let nValue = values[0]
  if nValue < 1 or nValue > 30: return -1
  let n = int(nValue)
  if int(length) != n + 1: return -1
  for i in 0 ..< n:
    if values[i + 1] < 1 or values[i + 1] > 1000: return -1
  var profit: array[31, int64]
  for rod in 1 .. n:
    var best: int64 = 0
    for cut in 1 .. rod:
      let candidate = values[cut] + profit[rod - cut]
      if candidate > best: best = candidate
    profit[rod] = best
  profit[n]
