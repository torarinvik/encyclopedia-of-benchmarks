const MaxBytes = 3

proc hash_djb2*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "hash_djb2".} =
  if input.isNil or length < 1 or length > MaxBytes + 1: return -1
  let countValue = input[0]
  if countValue < 0 or countValue > MaxBytes or length != csize_t(countValue) + 1: return -1
  var hash = 5381'u64
  for index in 0 ..< int(countValue):
    let byte = input[index + 1]
    if byte < 1 or byte > 127: return -1
    hash = hash * 33'u64 + uint64(byte)
  int64(hash)
