from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn sha0_rotate(value: UInt32, amount: Int) -> UInt32:
    return (value << amount) | (value >> (32 - amount))

@export("mibench_security_sha0")
fn mibench_security_sha0(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                          output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > 57: return -1
    let count_raw = input[0]
    if count_raw < 0 or count_raw > 55 or Int(length) != Int(count_raw) + 1: return -1
    let count = Int(count_raw)
    var block = InlineArray[UInt8, 64](fill=0)
    for i in range(count):
        if input[i + 1] < 0 or input[i + 1] > 255: return -1
        block[i] = UInt8(input[i + 1])
    block[count] = 128
    let bit_length = UInt64(count * 8)
    for i in range(8): block[63 - i] = UInt8((bit_length >> (8 * i)) & 255)
    var words = InlineArray[UInt32, 80](fill=0)
    for i in range(16):
        let at = 4 * i
        words[i] = (UInt32(block[at]) << 24) | (UInt32(block[at + 1]) << 16) | (UInt32(block[at + 2]) << 8) | UInt32(block[at + 3])
    for i in range(16, 80): words[i] = words[i - 3] ^ words[i - 8] ^ words[i - 14] ^ words[i - 16]
    var a = UInt32(0x67452301)
    var b = UInt32(0xefcdab89)
    var c = UInt32(0x98badcfe)
    var d = UInt32(0x10325476)
    var e = UInt32(0xc3d2e1f0)
    for i in range(80):
        var f: UInt32 = 0
        var k: UInt32 = 0
        if i < 20:
            f = (b & c) | ((~b) & d)
            k = 0x5a827999
        elif i < 40:
            f = b ^ c ^ d
            k = 0x6ed9eba1
        elif i < 60:
            f = (b & c) | (b & d) | (c & d)
            k = 0x8f1bbcdc
        else:
            f = b ^ c ^ d
            k = 0xca62c1d6
        let total = UInt64(sha0_rotate(a, 5)) + UInt64(f) + UInt64(e) + UInt64(words[i]) + UInt64(k)
        let temp = UInt32(total & 0xffffffff)
        e = d
        d = c
        c = sha0_rotate(b, 30)
        b = a
        a = temp
    var digest = InlineArray[UInt32, 5](fill=0)
    digest[0] = UInt32((UInt64(a) + UInt64(0x67452301)) & 0xffffffff)
    digest[1] = UInt32((UInt64(b) + UInt64(0xefcdab89)) & 0xffffffff)
    digest[2] = UInt32((UInt64(c) + UInt64(0x98badcfe)) & 0xffffffff)
    digest[3] = UInt32((UInt64(d) + UInt64(0x10325476)) & 0xffffffff)
    digest[4] = UInt32((UInt64(e) + UInt64(0xc3d2e1f0)) & 0xffffffff)
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < 20: return -2
    for i in range(5):
        for byte in range(4): output[4 * i + byte] = UInt8((digest[i] >> (24 - 8 * byte)) & 255)
    return 20
