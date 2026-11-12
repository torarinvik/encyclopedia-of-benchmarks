const MaxTableSize = 256
const DigestMask = 0x7fffffffffffffff'u64

type I64Input = ptr UncheckedArray[int64]

proc hpcc_random_access*(input: I64Input, length: csize_t): int64 {.cdecl, exportc: "hpcc_random_access".} =
  if input == nil or length != csize_t(1): return -1
  let sizeValue = input[0]
  if sizeValue < 2 or sizeValue > MaxTableSize.int64: return -1
  if (sizeValue and (sizeValue - 1)) != 0: return -1

  let size = int(sizeValue)
  var table: array[MaxTableSize, uint64]
  for index in 0 ..< size:
    table[index] = uint64(index)

  var ran = 1'u64
  for _ in 0 ..< 4 * size:
    let feedback = if (ran shr 63) != 0: 7'u64 else: 0'u64
    ran = (ran shl 1) xor feedback
    let tableIndex = int(ran and uint64(size - 1))
    table[tableIndex] = table[tableIndex] xor ran

  var digest = 0'u64
  for index in 0 ..< size:
    digest = digest +% (uint64(index + 1) *% table[index])
  int64(digest and DigestMask)
