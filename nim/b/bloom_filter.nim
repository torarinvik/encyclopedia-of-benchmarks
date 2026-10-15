const MaxTraceValues = 256
const MaxKey = 1_000_000_000'i64

type
  I64Input = ptr UncheckedArray[int64]
  ByteOutput = ptr UncheckedArray[uint8]

proc bloom_filter*(trace: I64Input, length: csize_t, output: ByteOutput,
                   outputCapacity: csize_t): int64 {.cdecl, exportc: "bloom_filter".} =
  if length > MaxTraceValues or length mod 2 != 0: return -1
  var queryCount = csize_t(0)
  var index = csize_t(0)
  while index < length:
    let operation = trace[index]
    let key = trace[index + 1]
    if (operation != 1 and operation != 2) or key < 0 or key > MaxKey: return -1
    if operation == 2: inc queryCount
    index += 2
  if outputCapacity < queryCount: return -2

  var bits = 0'u64
  var written = csize_t(0)
  index = 0
  while index < length:
    let key = trace[index + 1]
    let first = int((key * 17 + 3) mod 64)
    let second = int((key * 31 + 7) mod 64)
    let firstMask = 1'u64 shl first
    let secondMask = 1'u64 shl second
    if trace[index] == 1:
      bits = bits or firstMask or secondMask
    else:
      output[written] = if (bits and firstMask) != 0 and (bits and secondMask) != 0: 1'u8 else: 0'u8
      inc written
    index += 2
  int64(written)
