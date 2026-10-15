## Reverse a DNA sequence and complement each base.
const MaxReverseComplementLength = 1000

proc reverseComplement*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "reverse_complement".} =
  if length > csize_t(MaxReverseComplementLength) or (length != 0 and input == nil): return -1
  let count = int(length)
  for index in 0 ..< count:
    let base = input[index]
    if base != ord('A') and base != ord('C') and base != ord('G') and base != ord('T'): return -1
  if outputCapacity < length or (length != 0 and output == nil): return -2
  for index in 0 ..< count:
    let base = input[count - 1 - index]
    let complement = if base == ord('A'): ord('T') elif base == ord('T'): ord('A') elif base == ord('C'): ord('G') else: ord('C')
    output[index] = uint8(complement)
  int64(length)
