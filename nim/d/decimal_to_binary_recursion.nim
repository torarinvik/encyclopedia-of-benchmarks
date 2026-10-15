## Recursively encode binary digits as a decimal integer, for inputs 0..1023.
func encodeBinaryDigits(value: int64): int64 =
  if value == 0: return 0
  (value mod 2) + 10 * encodeBinaryDigits(value div 2)

proc decimal_to_binary_recursion*(value: int64): int64
    {.cdecl, exportc: "decimal_to_binary_recursion".} =
  if value < 0 or value > 1023: return -1
  encodeBinaryDigits(value)
