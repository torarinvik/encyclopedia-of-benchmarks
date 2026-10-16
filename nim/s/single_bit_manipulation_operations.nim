proc single_bit_manipulation_operations*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "single_bit_manipulation_operations".} =
  if input.isNil or length != 3: return -1
  let opcode = input[0]; let number = input[1]; let position = input[2]
  if opcode < 0 or opcode > 5 or number < -2_147_483_648'i64 or number > 2_147_483_647'i64: return -1
  if opcode == 5:
    if position != -1: return -1
    return number and (number - 1)
  if position < 0 or position > 31: return -1
  let mask = 1'i64 shl int(position)
  case opcode
  of 0: number or mask
  of 1: number and (not mask)
  of 2: number xor mask
  of 3: int64((cast[uint64](number) shr int(position)) and 1'u64)
  of 4: (if (number and mask) != 0: 1'i64 else: 0'i64)
  else: -1
