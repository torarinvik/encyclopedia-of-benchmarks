from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import List

fn blake_rotr(x: UInt64, r: Int) -> UInt64: return (x >> r) | (x << (64 - r))
fn blake_add(a: UInt64, b: UInt64) -> UInt64: return UInt64(UInt128(a) + UInt128(b))

fn blake_mix(mut v: List[UInt64], a: Int, b: Int, c: Int, d: Int, x: UInt64, y: UInt64) -> None:
    v[a] = blake_add(blake_add(v[a], v[b]), x); v[d] = blake_rotr(v[d] ^ v[a], 32)
    v[c] = blake_add(v[c], v[d]); v[b] = blake_rotr(v[b] ^ v[c], 24)
    v[a] = blake_add(blake_add(v[a], v[b]), y); v[d] = blake_rotr(v[d] ^ v[a], 16)
    v[c] = blake_add(v[c], v[d]); v[b] = blake_rotr(v[b] ^ v[c], 63)

fn blake_compress(mut h: List[UInt64], block: List[UInt8], counter: UInt64, final: Bool) -> None:
    var iv = List[UInt64](capacity=8)
    iv.append(0x6a09e667f3bcc908); iv.append(0xbb67ae8584caa73b); iv.append(0x3c6ef372fe94f82b); iv.append(0xa54ff53a5f1d36f1)
    iv.append(0x510e527fade682d1); iv.append(0x9b05688c2b3e6c1f); iv.append(0x1f83d9abfb41bd6b); iv.append(0x5be0cd19137e2179)
    var sigma = List[Int](capacity=160)
    let perm = [0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15, 14,10,4,8,9,15,13,6,1,12,0,2,11,7,5,3, 11,8,12,0,5,2,15,13,10,14,3,6,7,1,9,4, 7,9,3,1,13,12,11,14,2,6,5,10,4,0,15,8, 9,0,5,7,2,4,10,15,14,1,11,12,6,8,3,13, 2,12,6,10,0,11,8,3,4,13,7,5,15,14,1,9, 12,5,1,15,14,13,4,10,0,7,6,3,9,2,8,11, 13,11,7,14,12,1,3,9,5,0,15,4,8,6,2,10, 6,15,14,9,11,3,0,8,12,2,13,7,1,4,10,5, 10,2,8,4,7,6,1,5,15,11,9,14,3,12,13,0]
    for x in perm: sigma.append(x)
    var m = List[UInt64](capacity=16)
    for i in range(16):
        var word: UInt64 = 0
        for j in range(8): word = word | (UInt64(block[i * 8 + j]) << (8 * j))
        m.append(word)
    var v = List[UInt64](capacity=16)
    for i in range(8): v.append(h[i])
    for i in range(8): v.append(iv[i])
    v[12] = v[12] ^ counter
    if final: v[14] = ~v[14]
    for round in range(12):
        let base = (round % 10) * 16
        blake_mix(v,0,4,8,12,m[sigma[base]],m[sigma[base+1]])
        blake_mix(v,1,5,9,13,m[sigma[base+2]],m[sigma[base+3]])
        blake_mix(v,2,6,10,14,m[sigma[base+4]],m[sigma[base+5]])
        blake_mix(v,3,7,11,15,m[sigma[base+6]],m[sigma[base+7]])
        blake_mix(v,0,5,10,15,m[sigma[base+8]],m[sigma[base+9]])
        blake_mix(v,1,6,11,12,m[sigma[base+10]],m[sigma[base+11]])
        blake_mix(v,2,7,8,13,m[sigma[base+12]],m[sigma[base+13]])
        blake_mix(v,3,4,9,14,m[sigma[base+14]],m[sigma[base+15]])
    for i in range(8): h[i] = h[i] ^ v[i] ^ v[i + 8]

@export("blake2b")
fn blake2b(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t, output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if length > 4096 or (length > 0 and input == UnsafePointer[Int64, ImmutAnyOrigin]()): return -1
    for i in range(Int(length)):
        if input[i] < 0 or input[i] > 255: return -1
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < 64: return -2
    var h = List[UInt64](capacity=8)
    h.append(0x6a09e667f3bcc908 ^ 0x01010040); h.append(0xbb67ae8584caa73b); h.append(0x3c6ef372fe94f82b); h.append(0xa54ff53a5f1d36f1)
    h.append(0x510e527fade682d1); h.append(0x9b05688c2b3e6c1f); h.append(0x1f83d9abfb41bd6b); h.append(0x5be0cd19137e2179)
    var consumed = 0; var counter: UInt64 = 0
    while Int(length) - consumed > 128:
        var block = List[UInt8](capacity=128)
        for i in range(128): block.append(UInt8(input[consumed + i]))
        counter += 128; blake_compress(h, block, counter, False); consumed += 128
    var last = List[UInt8](capacity=128)
    for i in range(128): last.append(0)
    let remainder = Int(length) - consumed
    for i in range(remainder): last[i] = UInt8(input[consumed + i])
    counter += UInt64(remainder); blake_compress(h, last, counter, True)
    for word in range(8):
        for b in range(8): output[word * 8 + b] = UInt8((h[word] >> (8 * b)) & 255)
    return 64
