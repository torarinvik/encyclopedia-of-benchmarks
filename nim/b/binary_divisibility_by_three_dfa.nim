## Decide binary divisibility by three with a three-state streaming DFA.
const MaxBits = 4096
const MaxInputLength = MaxBits + 2

proc binary_divisibility_by_three_dfa*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "binary_divisibility_by_three_dfa".} =
  if input.isNil or length == 0 or length > csize_t(MaxInputLength): return -1
  let bitCount = input[0]
  if bitCount < 1 or bitCount > MaxBits or length != csize_t(bitCount + 1): return -1
  var remainder = 0'i64
  for index in 1'u64 ..< uint64(length):
    if input[csize_t(index)] != 0 and input[csize_t(index)] != 1: return -1
    remainder = (2 * remainder + input[csize_t(index)]) mod 3
  if output.isNil or outputCapacity < 1: return -2

  output[0] = uint8(ord(remainder == 0))
  1
