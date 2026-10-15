## Return the parity of the set-bit count using Kernighan's bit clearing.
proc parity*(number: int64): int64 {.cdecl, exportc: "parity".} =
  if number < 0: return -1
  var current = number
  var parityValue = 0'i64
  while current != 0:
    parityValue = parityValue xor 1
    current = current and (current - 1)
  parityValue
