## Go's distinct-factor Liouville variant: (-1) raised to omega(n).
proc liouville*(input: int64): int64 {.cdecl, exportc: "liouville".} =
  if input < 1 or input > 2_147_483_647: return -2
  var remaining = uint64(input)
  var sign = 1'i64
  var factor = 2'u64
  while factor <= remaining div factor:
    if remaining mod factor == 0:
      sign = -sign
      while remaining mod factor == 0:
        remaining = remaining div factor
    if factor == 2: factor = 3 else: factor += 2
  if remaining > 1: sign = -sign
  sign
