const MaxTextLength = 128
const ChecksumBase = 1_100_000'i64

proc substring_minus*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "substring_minus".} =
  if values == nil or length < 1 or length > MaxTextLength: return -1
  for i in 0 ..< int(length):
    if values[i] < 1 or values[i] > 127: return -1
  let count = int(length) - 1
  var checksum = 0'i64
  for i in 0 ..< count: checksum += int64(i + 1) * values[i]
  int64(count) * ChecksumBase + checksum
