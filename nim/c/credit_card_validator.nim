const MaxTextLength = 64

## Validate an ASCII card string using the source prefix and Luhn rules.
proc credit_card_validator*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "credit_card_validator".} =
  if input == nil or length < 1 or length > csize_t(MaxTextLength + 1): return -1
  let n = input[0]
  if n < 0 or n > MaxTextLength or length != csize_t(n + 1): return -1
  var allDigits = true
  for i in 0 ..< int(n):
    let ch = input[i + 1]
    if ch < 0 or ch > 127: return -1
    if ch < 48 or ch > 57: allDigits = false
  if not allDigits or n < 13 or n > 16: return 0
  let first = input[1] - 48
  let second = input[2] - 48
  if not (first == 4 or first == 5 or first == 6 or (first == 3 and (second == 4 or second == 5 or second == 7))): return 0
  var sum = 0
  for i in 0 ..< int(n):
    var digit = int(input[i + 1] - 48)
    if int64(i mod 2) == n mod 2:
      digit *= 2
      if digit > 9: digit -= 9
    sum += digit
  if sum mod 10 == 0: 1 else: 0
