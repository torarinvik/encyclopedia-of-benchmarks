proc problem115*(minBlockLength: int64): int64 {.cdecl, exportc: "problem115".} =
  if minBlockLength < 1 or minBlockLength > 100: return -1
  var ways: array[1024, int64]
  for i in 0..<int(minBlockLength): ways[i] = 1
  for n in int(minBlockLength)..<1024:
    ways[n] = 1
    for blockLength in int(minBlockLength)..n:
      for blockStart in 0..<(n - blockLength):
        ways[n] += ways[n - blockStart - blockLength - 1]
      inc ways[n]
    if ways[n] > 1_000_000: return int64(n)
  -1
