const MaxInput = 30_000'i64

## Count nondecreasing vowel strings via the pinned closed-form product.
proc count_sorted_vowel_strings*(n: int64): int64 {.cdecl, exportc: "count_sorted_vowel_strings".} =
  if n < 0 or n > MaxInput: return -1
  ((n + 4) * (n + 3) * (n + 2) * (n + 1)) div 24
