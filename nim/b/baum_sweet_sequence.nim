## Pack a bounded prefix of OEIS A086747 using a zero-run parity automaton.

proc baumSweetTerm(number: int64): int64 =
  if number == 0: return 0
  var mask = 1'i64
  while mask <= number div 2:
    mask *= 2
  var oddZeroRun = false
  while mask > 0:
    if (number and mask) != 0:
      if oddZeroRun: return 0
      oddZeroRun = false
    else:
      oddZeroRun = not oddZeroRun
    mask = mask div 2
  if oddZeroRun: 0 else: 1

proc baum_sweet_sequence*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "baum_sweet_sequence".} =
  if input.isNil or length != 1: return -1
  let count = input[0]
  if count < 0 or count > 63: return -1
  var packed = 0'i64
  var bit = 1'i64
  for index in 0 ..< int(count):
    if baumSweetTerm(int64(index)) != 0: packed += bit
    if index + 1 < int(count): bit *= 2
  packed
