proc feistelRk(k: uint32, r: uint32): uint32 =
  var p = 1'u32
  for _ in 0'u32..<(r + 2): p = p * k
  p xor k

proc feistelF(initial: uint32, k: uint32): uint32 =
  var x = initial
  for _ in 0..<32:
    x = ((x xor 0x55555555'u32) * x) mod k
    x = x xor k
  x

proc feistel_cipher_normalized*(a: ptr UncheckedArray[int64], length: csize_t): int64 {.cdecl, exportc: "feistel_cipher_normalized".} =
  if a.isNil or length != 3: return -1
  if a[0] < 0 or a[0] > 1 or a[1] < 1 or a[1] > 4294967295'i64: return -1
  let key = uint32(a[1])
  for i in 0'u32..<32'u32:
    if feistelRk(key, i) == 0: return -1
  let blockValue = cast[uint64](a[2])
  var left = uint32(blockValue shr 32)
  var right = uint32(blockValue)
  if a[0] == 0:
    for i in 0'u32..<32'u32:
      let t = right xor feistelF(left, feistelRk(key, i))
      right = left
      left = t
  else:
    for step in 0'u32..<32'u32:
      let i = 31'u32 - step
      let t = left xor feistelF(right, feistelRk(key, i))
      left = right
      right = t
  cast[int64]((uint64(left) shl 32) or uint64(right))
