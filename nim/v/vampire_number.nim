proc decimalLength(value: uint64): int =
  var remaining = value
  while true:
    inc result
    remaining = remaining div 10'u64
    if remaining == 0: break

proc vampire_number*(left, right: uint64): int64 {.cdecl, exportc: "vampire_number".} =
  if left < 1'u64 or left > 9999'u64 or right < 1'u64 or right > 9999'u64: return -1
  if decimalLength(left) != decimalLength(right): return 0
  var counts: array[10, int]
  var product = left * right
  var leftDigits = left
  var rightDigits = right
  while product != 0:
    inc counts[int(product mod 10'u64)]
    product = product div 10'u64
  while leftDigits != 0:
    dec counts[int(leftDigits mod 10'u64)]
    leftDigits = leftDigits div 10'u64
  while rightDigits != 0:
    dec counts[int(rightDigits mod 10'u64)]
    rightDigits = rightDigits div 10'u64
  for count in counts:
    if count != 0: return 0
  1
