const InvalidResult = -1'i64

proc reverse_factorial_recursive_impl(value, divisor: int64): int64 =
  if value == 1:
    if divisor == 1: return 1
    return divisor - 1
  if value mod divisor != 0: return InvalidResult
  reverse_factorial_recursive_impl(value div divisor, divisor + 1)

proc reverse_factorial_recursive*(value: int64): int64 {.cdecl, exportc: "reverse_factorial_recursive".} =
  if value < 1: return InvalidResult
  reverse_factorial_recursive_impl(value, 1)
