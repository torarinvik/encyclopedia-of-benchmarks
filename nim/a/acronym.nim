const MaxPhraseLength = 79

type I64Input = ptr UncheckedArray[int64]
type ByteOutput = ptr UncheckedArray[uint8]

proc acronym*(phrase: I64Input, length: csize_t, output: ByteOutput,
              outputCapacity: csize_t): int64 {.cdecl, exportc: "acronym".} =
  if length > MaxPhraseLength: return -1
  var required = csize_t(0)
  var index = csize_t(0)
  while index < length:
    let value = phrase[index]
    if value < 1'i64 or value > 127'i64: return -1
    if value != 32'i64 and (index == 0 or phrase[index - 1] == 32'i64): inc required
    inc index
  if outputCapacity < required: return -2
  var written = csize_t(0)
  index = 0
  while index < length:
    let value = phrase[index]
    if value != 32'i64 and (index == 0 or phrase[index - 1] == 32'i64):
      output[written] = uint8(if value >= 97'i64 and value <= 122'i64: value - 32 else: value)
      inc written
    inc index
  int64(written)
