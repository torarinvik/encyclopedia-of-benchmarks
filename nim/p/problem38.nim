proc is9Pandigital(value: int64): bool =
  if value < 100_000_000 or value > 999_999_999: return false
  var mask = 0'u16
  var remaining = value
  while remaining > 0:
    let digit = uint16(remaining mod 10)
    let bit = 1'u16 shl int(digit)
    if digit == 0 or (mask and bit) != 0: return false
    mask = mask or bit
    remaining = remaining div 10
  mask == 0x3fe'u16

proc problem38*(unused: int64): int64 {.cdecl, exportc: "problem38".} =
  if unused != 0: return -1
  for base in countdown(9999'i64, 5000'i64):
    let candidate = 100_002 * base
    if is9Pandigital(candidate): return candidate
  for base in countdown(333'i64, 100'i64):
    let candidate = 1_002_003 * base
    if is9Pandigital(candidate): return candidate
  -1
