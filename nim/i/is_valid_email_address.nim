proc asciiLetter(value: int64): bool =
  (value >= 65 and value <= 90) or (value >= 97 and value <= 122)
proc asciiDigit(value: int64): bool = value >= 48 and value <= 57
proc localSpecial(value: int64): bool =
  value in [33'i64,35,36,37,38,39,40,41,42,43,45,46,47,61,63,94,95,96,123,124,125,126]
proc localAllowed(value: int64): bool = asciiLetter(value) or asciiDigit(value) or localSpecial(value)
proc domainAllowed(value: int64): bool = asciiLetter(value) or asciiDigit(value) or value == 46 or value == 45

proc is_valid_email_address*(values: ptr UncheckedArray[int64], length: csize_t): int64 {.cdecl, exportc:"is_valid_email_address".} =
  if length > 320: return 0
  if values == nil and length > 0: return -1
  let n = int(length)
  for i in 0..<n:
    if values[i] < 0 or values[i] > 0x10ffff: return -1
  var at = n
  for i in 0..<n:
    if values[i] == 64:
      if at != n: return 0
      at = i
  if at == n: return 0
  let domainStart = at + 1
  if at > 64 or n - domainStart > 255: return 0
  for i in 0..<at:
    let value = values[i]
    if not localAllowed(value): return 0
    if value == 46 and (i == 0 or i + 1 == at or values[i - 1] == 46): return 0
  for i in domainStart..<n:
    let value = values[i]
    if not domainAllowed(value): return 0
    if value == 45 and i == domainStart: return 0
    if value == 46 and (i == domainStart or i + 1 == n or values[i - 1] == 46): return 0
  1
