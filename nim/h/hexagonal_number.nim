## Return the nth hexagonal number for a JS-safe positive index.
proc hexagonal_number*(number: int64): int64 {.cdecl, exportc: "hexagonal_number".} =
  if number < 1 or number > 67_108_864: return -1
  number * (2 * number - 1)
