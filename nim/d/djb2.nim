const MaxBytes = 64
const MaxParsedBytes = 65
const UInt32Modulus = 4_294_967_296'u64

proc djb2*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "djb2".} =
  if length > csize_t(MaxParsedBytes) or (length > 0 and input == nil): return -1
  if length > csize_t(MaxBytes): return -1
  var hash = 5381'u64
  for index in 0 ..< int(length):
    let codePoint = input[index]
    if codePoint < 0 or codePoint > 255: return -1
    hash = (hash * 33'u64 + uint64(codePoint)) mod UInt32Modulus
  int64(hash)
