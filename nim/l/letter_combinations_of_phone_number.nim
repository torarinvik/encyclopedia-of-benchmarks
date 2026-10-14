## Recursively enumerate 2–9 phone keypad letters into fixed-width output slots.
proc letterCount(digit: int64): csize_t =
  if digit == 7 or digit == 9: 4 else: 3

proc letterBase(digit: int64): uint8 =
  case digit
  of 2: uint8(ord('a'))
  of 3: uint8(ord('d'))
  of 4: uint8(ord('g'))
  of 5: uint8(ord('j'))
  of 6: uint8(ord('m'))
  of 7: uint8(ord('p'))
  of 8: uint8(ord('t'))
  else: uint8(ord('w'))

proc expand(digits: ptr UncheckedArray[int64], length, index: csize_t,
            output: ptr UncheckedArray[uint8], outputOffset, combinationCount: csize_t) =
  if index == length: return
  let alternatives = letterCount(digits[index])
  let blockCount = combinationCount div alternatives
  let base = letterBase(digits[index])
  for letter in 0'u64 ..< uint64(alternatives):
    let branchOffset = outputOffset + csize_t(letter) * blockCount * length
    for row in 0'u64 ..< uint64(blockCount):
      output[branchOffset + csize_t(row) * length + index] = base + uint8(letter)
    expand(digits, length, index + 1, output, branchOffset, blockCount)

proc letter_combinations_of_phone_number*(digits: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "letter_combinations_of_phone_number".} =
  if length == 0: return 0
  if length > 6 or digits == nil: return -1
  var count = csize_t(1)
  for index in 0'u64 ..< uint64(length):
    let digit = digits[csize_t(index)]
    if digit < 2 or digit > 9: return -1
    count *= letterCount(digit)
  let required = count * length
  if outputCapacity < required or output == nil: return -2
  expand(digits, length, 0, output, 0, count)
  int64(count)
