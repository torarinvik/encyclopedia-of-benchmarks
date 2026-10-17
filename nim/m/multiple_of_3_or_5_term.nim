proc multiple_of_3_or_5_term*(n: int64): int64
    {.cdecl, exportc: "multiple_of_3_or_5_term".} =
  if n < 0 or n > 1_000_000_000: return -1
  if n mod 3 == 0 or n mod 5 == 0: n else: 0
