## Recursively encode octal digits as a decimal integer.
func encodeOctalDigits(value: int64): int64 =
  if value == 0: return 0
  encodeOctalDigits(value div 8) * 10 + value mod 8

proc decimal_to_octal_recursion*(value: int64): int64
    {.cdecl, exportc: "decimal_to_octal_recursion".} =
  if value < 0 or value > 295600127: return -1
  encodeOctalDigits(value)
