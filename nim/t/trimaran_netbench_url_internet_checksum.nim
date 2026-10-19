## Modified source-related port of NetBench url.c; see bundled LICENSE_NOTICE.txt.
proc trimaran_netbench_url_internet_checksum*(values: ptr UncheckedArray[int64], length: csize_t): int64 {.cdecl, exportc.} =
  const maxBytes = 64
  if values == nil or length < 2 or length > maxBytes + 2: return -1
  let mode = values[0]
  let countValue = values[1]
  if (mode != 0 and mode != 1) or countValue < 0 or countValue > maxBytes or
      length != csize_t(countValue) + 2: return -1
  let count = int(countValue)
  for i in 0..<count:
    if values[i + 2] < 0 or values[i + 2] > 255: return -1
  var sum = 0'u64
  var i = 0
  while i + 1 < count:
    let word = uint64(values[i + 2]) or (uint64(values[i + 3]) shl 8)
    sum = sum -% (word +% 1'u64)
    i += 2
  if i < count: sum = sum +% uint64(values[i + 2])
  while (sum shr 16) != 0: sum = (sum and 0xffff'u64) + (sum shr 16)
  if mode == 1: sum = ((sum shr 8) or ((sum shl 8) and 0xff00'u64)) and 0xffff'u64
  result = int64(sum)
