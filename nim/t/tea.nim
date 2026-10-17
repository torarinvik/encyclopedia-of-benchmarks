const
  TeaDelta = 0x9E3779B9'u32
  TeaDecryptSum = 0xC6EF3720'u32

proc combineWords(low: uint32, high: uint32): uint64 =
  (uint64(high) shl 32) or uint64(low)

proc teaEncrypt(block: uint64, key0: uint64, key1: uint64): uint64 =
  var b0 = uint32(block)
  var b1 = uint32(block shr 32)
  let k0 = uint32(key0)
  let k1 = uint32(key0 shr 32)
  let k2 = uint32(key1)
  let k3 = uint32(key1 shr 32)
  var total = 0'u32
  for _ in 0 ..< 32:
    total = total +% TeaDelta
    b0 = b0 +% (((b1 shl 4) +% k0) xor (b1 +% total) xor ((b1 shr 5) +% k1))
    b1 = b1 +% (((b0 shl 4) +% k2) xor (b0 +% total) xor ((b0 shr 5) +% k3))
  (uint64(b1) shl 32) or uint64(b0)

proc teaDecrypt(block: uint64, key0: uint64, key1: uint64): uint64 =
  var b0 = uint32(block)
  var b1 = uint32(block shr 32)
  let k0 = uint32(key0)
  let k1 = uint32(key0 shr 32)
  let k2 = uint32(key1)
  let k3 = uint32(key1 shr 32)
  var total = TeaDecryptSum
  for _ in 0 ..< 32:
    b1 = b1 -% (((b0 shl 4) +% k2) xor (b0 +% total) xor ((b0 shr 5) +% k3))
    b0 = b0 -% (((b1 shl 4) +% k0) xor (b1 +% total) xor ((b1 shr 5) +% k1))
    total = total -% TeaDelta
  (uint64(b1) shl 32) or uint64(b0)

proc storeU64Le(output: ptr UncheckedArray[uint8], offset: int, value: uint64) =
  for byte in 0 ..< 8:
    output[offset + byte] = uint8((value shr (byte * 8)) and 255'u64)

## Return ciphertext and the decrypted round-trip block as little-endian u64s.
proc tea*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "tea".} =
  if input == nil or length != 6: return -1
  for index in 0 ..< 6:
    if input[index] < -2147483648'i64 or input[index] > 2147483647'i64: return -1
  if output == nil or outputCapacity < 16: return -2
  let word = proc(index: int): uint32 = cast[uint32](int32(input[index]))
  let block = combineWords(word(0), word(1))
  let key0 = combineWords(word(2), word(3))
  let key1 = combineWords(word(4), word(5))
  let ciphertext = teaEncrypt(block, key0, key1)
  let recovered = teaDecrypt(ciphertext, key0, key1)
  storeU64Le(output, 0, ciphertext)
  storeU64Le(output, 8, recovered)
  16
