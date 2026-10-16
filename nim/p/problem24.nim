proc problem24*(ignored: int64): int64 {.cdecl, exportc: "problem24".} =
  if ignored != 0: return -1
  var rank = 999999'i64
  var factorial = 362880'i64
  var used = 0'i64
  var answer = 0'i64
  var slots = 10'i64
  while slots > 0:
    var choice = rank div factorial
    rank = rank mod factorial
    var selected = -1'i64
    var digit = 0'i64
    while digit < 10:
      let bit = 1'i64 shl int(digit)
      if (used and bit) == 0:
        if choice == 0:
          selected = digit
          used = used or bit
          break
        dec choice
      inc digit
    answer = answer * 10 + selected
    if slots > 1: factorial = factorial div (slots - 1)
    dec slots
  answer
