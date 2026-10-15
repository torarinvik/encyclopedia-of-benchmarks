## Compute T(n) = n(n+1)/2 without an overflowing intermediate product.
proc triangular_number*(input: int64): int64 {.cdecl, exportc: "triangular_number".} =
  if input < 0 or input > 4_294_967_295'i64: return -1
  let left = if input mod 2 == 0: input div 2 else: input
  let right = if input mod 2 == 0: input + 1 else: (input + 1) div 2
  left * right
