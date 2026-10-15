## Preserve the source's factor-of-two reduction for Proth membership.
proc is_proth_number*(input: int64): int64 {.cdecl, exportc: "is_proth_number".} =
  if input <= 0: return -1
  if input == 1: return 0

  var remainder = input - 1
  var exponent = 0
  while remainder mod 2 == 0:
    inc exponent
    remainder = remainder div 2
  if remainder < (1'i64 shl exponent): 1'i64 else: 0'i64
