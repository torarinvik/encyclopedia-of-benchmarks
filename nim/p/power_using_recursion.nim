proc powerRecursive(base, exponent: int64): int64 =
  if exponent == 0: return 1
  base * powerRecursive(base, exponent - 1)

proc power_using_recursion*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "power_using_recursion".} =
  if input == nil or length != 2: return -1
  let base = input[0]
  let exponent = input[1]
  if base < -10 or base > 10 or exponent < 0 or exponent > 15: return -1
  powerRecursive(base, exponent)
