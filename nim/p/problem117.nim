proc problem117*(length: int64): int64 {.cdecl, exportc: "problem117".} =
  if length < 0 or length > 67: return -1
  var ways: array[68, int64]
  ways[0] = 1
  for row in 1 .. int(length):
    ways[row] = ways[row - 1]
    if row >= 2: ways[row] += ways[row - 2]
    if row >= 3: ways[row] += ways[row - 3]
    if row >= 4: ways[row] += ways[row - 4]
  ways[int(length)]
