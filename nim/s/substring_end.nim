const MaxTextLength = 128
const ChecksumBase = 1_100_000'i64

proc substring_end*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "substring_end".} =
  if values == nil or length < 1 or length > MaxTextLength + 1: return -1
  let textLength = int(length) - 1
  let start = values[0]
  if start < 0 or start > int64(textLength): return -1
  for i in 0 ..< textLength:
    if values[i + 1] < 1 or values[i + 1] > 127: return -1
  let count = textLength - int(start)
  var checksum = 0'i64
  for i in 0 ..< count: checksum += int64(i + 1) * values[int(start) + i + 1]
  int64(count) * ChecksumBase + checksum
