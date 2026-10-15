## XOR-swap a bounded signed pair and pack the returned values into i64.
proc xor_swap_two_integers*(first, second: int64): int64
    {.cdecl, exportc: "xor_swap_two_integers".} =
  if first < -32768 or first > 32767 or second < -32768 or second > 32767: return -1
  var a = first
  var b = second
  if a < 0: a += 65536
  if b < 0: b += 65536
  a = a xor b
  b = a xor b
  a = a xor b
  let swappedFirst = if a >= 32768: a - 65536 else: a
  let swappedSecond = if b >= 32768: b - 65536 else: b
  (swappedFirst + 32768) * 65536 + (swappedSecond + 32768)
