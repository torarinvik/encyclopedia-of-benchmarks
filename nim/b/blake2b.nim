const MaxInput = 4096
const BlockBytes = 128
const IV: array[8, uint64] = [
  0x6a09e667f3bcc908'u64, 0xbb67ae8584caa73b'u64, 0x3c6ef372fe94f82b'u64, 0xa54ff53a5f1d36f1'u64,
  0x510e527fade682d1'u64, 0x9b05688c2b3e6c1f'u64, 0x1f83d9abfb41bd6b'u64, 0x5be0cd19137e2179'u64]
const Sigma: array[10, array[16, int]] = [
  [0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15], [14,10,4,8,9,15,13,6,1,12,0,2,11,7,5,3],
  [11,8,12,0,5,2,15,13,10,14,3,6,7,1,9,4], [7,9,3,1,13,12,11,14,2,6,5,10,4,0,15,8],
  [9,0,5,7,2,4,10,15,14,1,11,12,6,8,3,13], [2,12,6,10,0,11,8,3,4,13,7,5,15,14,1,9],
  [12,5,1,15,14,13,4,10,0,7,6,3,9,2,8,11], [13,11,7,14,12,1,3,9,5,0,15,4,8,6,2,10],
  [6,15,14,9,11,3,0,8,12,2,13,7,1,4,10,5], [10,2,8,4,7,6,1,5,15,11,9,14,3,12,13,0]]

proc rotr64(x: uint64, n: int): uint64 = (x shr n) or (x shl (64 - n))
proc add64(a, b: uint64): uint64 =
  let low = (a and 0xffff_ffff'u64) + (b and 0xffff_ffff'u64)
  let high = (a shr 32) + (b shr 32) + (low shr 32)
  ((high and 0xffff_ffff'u64) shl 32) or (low and 0xffff_ffff'u64)
proc mix(v: var array[16, uint64], a, b, c, d: int, x, y: uint64) =
  v[a] = add64(add64(v[a], v[b]), x)
  v[d] = rotr64(v[d] xor v[a], 32)
  v[c] = add64(v[c], v[d])
  v[b] = rotr64(v[b] xor v[c], 24)
  v[a] = add64(add64(v[a], v[b]), y)
  v[d] = rotr64(v[d] xor v[a], 16)
  v[c] = add64(v[c], v[d])
  v[b] = rotr64(v[b] xor v[c], 63)

proc compress(h: var array[8, uint64], buffer: array[BlockBytes, uint8], counter: uint64, last: bool) =
  var m: array[16, uint64]
  for i in 0..<16:
    for byte in 0..<8: m[i] = m[i] or (uint64(buffer[i * 8 + byte]) shl (8 * byte))
  var v: array[16, uint64]
  for i in 0..<8: v[i] = h[i]; v[i + 8] = IV[i]
  v[12] = v[12] xor counter
  if last: v[14] = not v[14]
  for round in 0..<12:
    let s = Sigma[round mod 10]
    mix(v,0,4,8,12,m[s[0]],m[s[1]]); mix(v,1,5,9,13,m[s[2]],m[s[3]])
    mix(v,2,6,10,14,m[s[4]],m[s[5]]); mix(v,3,7,11,15,m[s[6]],m[s[7]])
    mix(v,0,5,10,15,m[s[8]],m[s[9]]); mix(v,1,6,11,12,m[s[10]],m[s[11]])
    mix(v,2,7,8,13,m[s[12]],m[s[13]]); mix(v,3,4,9,14,m[s[14]],m[s[15]])
  for i in 0..<8: h[i] = h[i] xor v[i] xor v[i + 8]

proc blake2b*(input: ptr UncheckedArray[int64], length: csize_t,
              output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc: "blake2b".} =
  if length > MaxInput or (length > 0 and input.isNil): return -1
  let n = int(length)
  for i in 0..<n:
    if input[i] < 0 or input[i] > 255: return -1
  if output.isNil or capacity < 64: return -2
  var h = IV
  h[0] = h[0] xor 0x01010040'u64
  var buffer: array[BlockBytes, uint8]
  var consumed = 0
  var counter = 0'u64
  while n - consumed > BlockBytes:
    for i in 0..<BlockBytes: buffer[i] = uint8(input[consumed + i])
    counter += BlockBytes.uint64
    compress(h, buffer, counter, false)
    consumed += BlockBytes
    buffer = default(array[BlockBytes, uint8])
  let remaining = n - consumed
  for i in 0..<remaining: buffer[i] = uint8(input[consumed + i])
  counter += remaining.uint64
  compress(h, buffer, counter, true)
  for word in 0..<8:
    for byte in 0..<8: output[word * 8 + byte] = uint8((h[word] shr (8 * byte)) and 255)
  64
