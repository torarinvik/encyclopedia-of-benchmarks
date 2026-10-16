const MaxTextLength = 64

proc validate_credit_card*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "validate_credit_card".} =
  if input == nil or length < 1 or length > (MaxTextLength + 1).csize_t: return -1
  let n = input[0]
  if n < 0 or n > MaxTextLength or length != (n + 1).csize_t: return -1
  for i in 0 ..< n.int:
    if input[i + 1] < 0 or input[i + 1] > 127: return -1
  if n < 13 or n > 16: return 0
  for i in 0 ..< n.int:
    if input[i + 1] < 48 or input[i + 1] > 57: return 0
  let first = input[1] - 48
  let second = input[2] - 48
  if not (first == 4 or first == 5 or first == 6 or
      (first == 3 and (second == 4 or second == 5 or second == 7))): return 0
  var total = 0'i64
  for i in 0 ..< n.int:
    var digit = input[i + 1] - 48
    if i mod 2 == 0:
      digit *= 2
      if digit > 9: digit -= 9
    total += digit
  if total mod 10 == 0: 1 else: 0
