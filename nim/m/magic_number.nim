## Positive n is magic when its decimal digit root is one.
proc magic_number*(n: int64): int64 {.cdecl, exportc: "magic_number".} =
  if n > 0 and n mod 9 == 1: return 1
  return 0
