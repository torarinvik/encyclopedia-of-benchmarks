proc problem124*(nMax, k: int64): int64 {.cdecl, exportc: "problem124".} =
  if nMax < 1 or nMax > 100_000 or k < 1 or k > nMax: return -1
  let n = int(nMax)
  var radicals: array[100_001, int64]
  var counts: array[100_001, int64]
  for i in 1..n: radicals[i] = 1
  for p in 2..n:
    if radicals[p] == 1:
      for multiple in countup(p, n, p): radicals[multiple] *= int64(p)
  for i in 1..n: inc counts[int(radicals[i])]
  var remaining = k
  for rad in 1..n:
    if remaining > counts[rad]:
      remaining -= counts[rad]
    else:
      for value in 1..n:
        if radicals[value] == int64(rad):
          dec remaining
          if remaining == 0: return int64(value)
  -1
