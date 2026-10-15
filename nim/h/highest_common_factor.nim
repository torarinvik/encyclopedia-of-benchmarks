proc highestCommonFactorImpl(x, y: uint64): uint64 =
  if x == 0: return y
  if y == 0: return x
  if x == y: return x
  if y > x:
    return highestCommonFactorImpl(y - x, x)
  return highestCommonFactorImpl(x - y, y)

proc highest_common_factor*(x, y: uint64): int64
    {.cdecl, exportc: "highest_common_factor".} =
  int64(highestCommonFactorImpl(x, y))
