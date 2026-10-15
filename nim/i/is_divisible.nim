## Remainder check from the pinned JavaScript and TypeScript sources.
proc is_divisible*(dividend, divisor: uint64): int64 {.cdecl, exportc: "is_divisible".} =
  if dividend > 1_000_000_000 or divisor == 0 or divisor > 1_000_000_000:
    return -1
  return if dividend mod divisor == 0: 1 else: 0
