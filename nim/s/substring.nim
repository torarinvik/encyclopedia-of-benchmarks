const MaxTextLength = 128
const MaxRequestedCount = 64'i64
const ChecksumBase = 300_000'i64

proc substring*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "substring".} =
  if values == nil or length < 2 or length > MaxTextLength + 2: return -1
  let textLength = int(length) - 2
  let start = values[0]
  let requested = values[1]
  if start < 0 or start > int64(textLength) or requested < 0 or requested > MaxRequestedCount: return -1
  for i in 0 ..< textLength:
    if values[i + 2] < 1 or values[i + 2] > 127: return -1
  let remaining = textLength - int(start)
  var count = int(requested)
  if count == 0 and remaining > 0: count = 1
  if count > remaining: count = remaining
  var checksum = 0'i64
  for i in 0 ..< count: checksum += int64(i + 1) * values[int(start) + i + 2]
  int64(count) * ChecksumBase + checksum
