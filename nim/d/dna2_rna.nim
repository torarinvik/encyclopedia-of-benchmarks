type
  I64Input = ptr UncheckedArray[int64]
  ByteOutput = ptr UncheckedArray[uint8]

const MaxInputValues = 1001

proc dna2_rna*(values: I64Input, length: csize_t, output: ByteOutput,
               outputCapacity: csize_t): int64 {.cdecl, exportc: "dna2_rna".} =
  if values == nil or length < 1 or length > MaxInputValues or values[0] != 0: return -1
  let count = length - 1
  for index in 1 ..< length:
    if values[index] < ord('A') or values[index] > ord('Z'): return -1
  if outputCapacity < count or (count != 0 and output == nil): return -2
  for index in 0 ..< count:
    let base = values[index + 1]
    output[index] = uint8(if base == ord('T'): ord('U') else: int(base))
  int64(count)
