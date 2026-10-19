from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

fn feistel_round_key(key: UInt32, round: UInt32) -> UInt32:
    var power: UInt32 = 1
    for i in range(round + 2): power *= key
    return power ^ key

fn feistel_valid_key(key: UInt32) -> Bool:
    for i in range(32):
        if feistel_round_key(key, UInt32(i)) == 0: return False
    return True

fn feistel_f(x_in: UInt32, key: UInt32) -> UInt32:
    var x = x_in
    for i in range(32):
        x = ((x ^ 0x55555555) * x) % key
        x ^= key
    return x

@export("feistel_cipher_normalized")
fn feistel_cipher_normalized(a: UnsafePointer[Int64, ImmutAnyOrigin], n: c_size_t) abi("C") -> Int64:
    if a == UnsafePointer[Int64, ImmutAnyOrigin]() or n != 3 or a[0] < 0 or a[0] > 1 or a[1] < 1 or a[1] > 4294967295: return -1
    let bits = UInt64(a[2])
    var left = UInt32(bits >> 32)
    var right = UInt32(bits & 0xffffffff)
    let key = UInt32(a[1])
    if not feistel_valid_key(key): return -1
    if a[0] == 0:
        for i in range(32):
            let temp = right ^ feistel_f(left, feistel_round_key(key, UInt32(i)))
            right = left
            left = temp
    else:
        var i: Int64 = 31
        while i >= 0:
            let temp = left ^ feistel_f(right, feistel_round_key(key, UInt32(i)))
            left = right
            right = temp
            i -= 1
    return Int64((UInt64(left) << 32) | UInt64(right))
