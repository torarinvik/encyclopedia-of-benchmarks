type
  I64Input = ptr UncheckedArray[int64]
  ByteOutput = ptr UncheckedArray[uint8]

const MaxInputValues = 1001

proc rna_transcription*(values: I64Input, length: csize_t, output: ByteOutput,
                        outputCapacity: csize_t): int64 {.cdecl, exportc: "rna_transcription".} =
  if values == nil or length < 1 or length > MaxInputValues or values[0] != 0: return -1
  let count = length - 1
  for index in 1 ..< length:
    let base = values[index]
    if base != ord('A') and base != ord('C') and base != ord('G') and base != ord('T'): return -1
  if outputCapacity < count or (count != 0 and output == nil): return -2
  for index in 0 ..< count:
    case values[index + 1]
    of ord('A'): output[index] = uint8(ord('U'))
    of ord('C'): output[index] = uint8(ord('G'))
    of ord('G'): output[index] = uint8(ord('C'))
    else: output[index] = uint8(ord('A'))
  int64(count)
