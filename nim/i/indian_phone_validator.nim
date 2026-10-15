proc isAsciiWhitespace(value: int64): bool =
  value in [9'i64, 10'i64, 11'i64, 12'i64, 13'i64, 32'i64]

proc mobileTail(phone: ptr UncheckedArray[int64], ending, position: int): bool =
  if position > ending or ending - position != 10: return false
  if phone[position] < 55 or phone[position] > 57: return false
  for i in 1 ..< 10:
    if phone[position + i] < 48 or phone[position + i] > 57: return false
  true

proc indian_phone_validator*(phone: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "indian_phone_validator".} =
  if phone.isNil or length == 0 or length > 18: return -1
  for i in 0 ..< int(length):
    if phone[i] < 0 or phone[i] > 127: return -1

  var ending = int(length)
  if phone[ending - 1] == 10: dec ending
  var prefix = 0
  if ending >= 3 and phone[0] == 43 and phone[1] == 57 and phone[2] == 49:
    prefix = 3
    if prefix < ending and (phone[prefix] == 45 or isAsciiWhitespace(phone[prefix])): inc prefix

  for zero in 0 .. 1:
    var afterZero = prefix
    if zero == 1:
      if afterZero >= ending or phone[afterZero] != 48: continue
      inc afterZero
    for country in 0 .. 1:
      var position = afterZero
      if country == 1:
        if position + 2 > ending or phone[position] != 57 or phone[position + 1] != 49: continue
        position += 2
      if mobileTail(phone, ending, position): return 1
  0
