const MaxStart = 1_000_000

type I64Input = ptr UncheckedArray[int64]
type ByteOutput = ptr UncheckedArray[uint8]

proc nextTerm(value: int64): int64 =
  if value mod 2 == 0: value div 2 else: 3 * value + 1

proc storeI64Le(output: ByteOutput, offset: csize_t, value: int64) =
  let bits = cast[uint64](value)
  for byte in 0 ..< 8:
    output[offset + csize_t(byte)] = uint8((bits shr (byte * 8)) and 0xff'u64)

proc collatz_sequence*(input: I64Input, length: csize_t, output: ByteOutput,
                       outputCapacity: csize_t): int64 {.cdecl, exportc: "collatz_sequence".} =
  if length != 1 or input[0] < 1'i64 or input[0] > MaxStart: return -1
  var current = input[0]
  var termCount = csize_t(1)
  while current != 1:
    current = nextTerm(current)
    inc termCount
  let required = termCount * 8
  if outputCapacity < required: return -2
  current = input[0]
  var written = csize_t(0)
  while true:
    storeI64Le(output, written, current)
    written += 8
    if current == 1: break
    current = nextTerm(current)
  int64(written)
