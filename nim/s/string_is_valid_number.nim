proc string_is_valid_number*(bytes: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "string_is_valid_number".} =
  if length > 256 or (length != 0 and bytes.isNil):
    return -1
  for i in 0 ..< int(length):
    if bytes[i] < 0 or bytes[i] > 127:
      return -1

  var state = 0
  for i in 0 ..< int(length):
    let ch = bytes[i]
    if ch >= 48 and ch <= 57:
      if state == 0 or state == 1: state = 2
      elif state == 3: state = 4
      elif state == 5 or state == 6: state = 7
      elif state != 2 and state != 4 and state != 7: return 0
    elif ch == 43 or ch == 45:
      if state == 0: state = 1
      elif state == 5: state = 6
      else: return 0
    elif ch == 46:
      if state == 0 or state == 1: state = 3
      elif state == 2: state = 4
      else: return 0
    elif ch == 101 or ch == 69:
      if state == 2 or state == 4: state = 5
      else: return 0
    else:
      return 0
  if state == 2 or state == 4 or state == 7: 1 else: 0
