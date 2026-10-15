## Liouville's function: (-1) raised to the number of prime factors with multiplicity.
proc liouville_lambda*(input: int64): int64 {.cdecl, exportc: "liouville_lambda".} =
  if input < 1 or input > 2_147_483_647: return -1
  var remaining = uint64(input)
  var sign = 1'i64
  var factor = 2'u64
  while factor <= remaining div factor:
    while remaining mod factor == 0:
      remaining = remaining div factor
      sign = -sign
    if factor == 2: factor = 3 else: factor += 2
  if remaining > 1: sign = -sign
  sign
