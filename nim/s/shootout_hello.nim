const SourceCalls = 1'i64
const OutputBytes = 13
const SourceOutput = "hello world\n\n"

proc shootout_hello*(calls: int64, output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64 {.cdecl, exportc: "shootout_hello".} =
  if calls != SourceCalls: return -1
  if output.isNil or outputCapacity < csize_t(OutputBytes): return -2
  var staged: array[OutputBytes, uint8]
  for index in 0 ..< OutputBytes: staged[index] = uint8(ord(SourceOutput[index]))
  for index in 0 ..< OutputBytes: output[index] = staged[index]
  int64(OutputBytes)
