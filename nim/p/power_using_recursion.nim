type I64Input = ptr UncheckedArray[int64]

proc powerUsingRecursionValue(base: int64, exponent: int64): int64 =
  if exponent == 0: return 1
  base * powerUsingRecursionValue(base, exponent - 1)

proc power_using_recursion*(input: I64Input, length: csize_t): int64
    {.cdecl, exportc: "power_using_recursion".} =
  if input == nil or length != csize_t(2): return -1
  let base = input[0]
  let exponent = input[1]
  if base < -10 or base > 10 or exponent < 0 or exponent > 15: return -1
  powerUsingRecursionValue(base, exponent)
