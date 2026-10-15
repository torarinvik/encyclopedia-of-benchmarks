## Hash ASCII byte arrays with the pinned 64-bit SDBM recurrence.
const MaxBytes = 64
const HighBit = 1'u64 shl 63

proc signedBits(value: uint64): int64 =
  if value < HighBit: return int64(value)
  low(int64) + int64(value - HighBit)

proc hash_sdbm*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "hash_sdbm".} =
  if length == 0 or length > csize_t(MaxBytes) or input == nil: return -1
  var hash = 0'u64
  for index in 0 ..< int(length):
    let byte = input[index]
    if byte < 1 or byte > 127: return -1
    let value = uint64(byte)
    hash = value + (hash shl 6) + (hash shl 16) - hash
  signedBits(hash)
