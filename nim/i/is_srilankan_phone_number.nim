proc is_srilankan_phone_number*(phone: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "is_srilankan_phone_number".} =
  if phone.isNil or length == 0 or length > 15:
    return -1
  for i in 0 ..< int(length):
    if phone[i] < 0 or phone[i] > 127:
      return -1

  var prefixLength: int
  if phone[0] == 48:
    if length >= 4 and phone[1] == 48 and phone[2] == 57 and phone[3] == 52:
      prefixLength = 4
    else:
      prefixLength = 1
  elif length >= 2 and phone[0] == 57 and phone[1] == 52:
    prefixLength = 2
  elif length >= 3 and phone[0] == 43 and phone[1] == 57 and phone[2] == 52:
    prefixLength = 3
  else:
    return 0

  var cursor = prefixLength
  if cursor + 2 > int(length) or phone[cursor] != 55:
    return 0
  inc cursor
  let provider = phone[cursor]
  inc cursor
  if provider notin [48'i64, 49'i64, 50'i64, 52'i64, 53'i64, 54'i64, 55'i64, 56'i64]:
    return 0

  var endIndex = int(length)
  if phone[endIndex - 1] == 10:
    dec endIndex
  let remaining = endIndex - cursor
  if remaining == 8 and (phone[cursor] == 45 or phone[cursor] == 32):
    inc cursor
  elif remaining != 7:
    return 0
  for i in 0 ..< 7:
    if phone[cursor + i] < 48 or phone[cursor + i] > 57:
      return 0
  1
