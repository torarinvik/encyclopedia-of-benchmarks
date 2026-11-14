# Independent IDEA block profile; see the package NBENCH-LICENSE for attribution.
from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn idea_mul(a: Int, b: Int) -> Int:
    let x = 65536 if a == 0 else a
    let y = 65536 if b == 0 else b
    let product = (x * y) % 65537
    return 0 if product == 65536 else product

fn idea_inverse(value: Int) -> Int:
    var old_r = 65537
    var r = 65536 if value == 0 else value
    var old_coefficient = 0
    var coefficient = 1
    while r != 0:
        let quotient = old_r // r
        let next_r = old_r - quotient * r
        let next_coefficient = old_coefficient - quotient * coefficient
        old_r = r
        r = next_r
        old_coefficient = coefficient
        coefficient = next_coefficient
    var inverse = old_coefficient % 65537
    if inverse < 0: inverse += 65537
    return 0 if inverse == 65536 else inverse

@export("idea_encrypt_decrypt")
fn idea_encrypt_decrypt(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                        output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length != 12: return -1
    var state = InlineArray[Int, 8](fill=0)
    var block = InlineArray[Int, 4](fill=0)
    for i in range(12):
        if input[i] < 0 or input[i] > 65535: return -1
        if i < 8: state[i] = Int(input[i])
        else: block[i - 8] = Int(input[i])
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < 16: return -2
    var keys = InlineArray[Int, 52](fill=0)
    var written = 0
    while written < 52:
        for i in range(min(8, 52 - written)): keys[written + i] = state[i]
        var rotated = InlineArray[Int, 8](fill=0)
        for i in range(8):
            rotated[i] = ((state[(i + 1) % 8] << 9) | (state[(i + 2) % 8] >> 7)) & 65535
        state = rotated
        written += 8
    var x1 = block[0]
    var x2 = block[1]
    var x3 = block[2]
    var x4 = block[3]
    for round in range(8):
        let k = round * 6
        let a = idea_mul(x1, keys[k])
        let b = (x2 + keys[k + 1]) & 65535
        let c = (x3 + keys[k + 2]) & 65535
        let d = idea_mul(x4, keys[k + 3])
        let p = idea_mul(a ^ c, keys[k + 4])
        let q = idea_mul(((b ^ d) + p) & 65535, keys[k + 5])
        let r = (p + q) & 65535
        x1 = a ^ q
        x2 = c ^ q
        x3 = b ^ r
        x4 = d ^ r
    let cipher = InlineArray[Int, 4](idea_mul(x1, keys[48]), (x3 + keys[49]) & 65535,
                                    (x2 + keys[50]) & 65535, idea_mul(x4, keys[51]))
    x1 = idea_mul(cipher[0], idea_inverse(keys[48]))
    x2 = (cipher[2] - keys[50]) & 65535
    x3 = (cipher[1] - keys[49]) & 65535
    x4 = idea_mul(cipher[3], idea_inverse(keys[51]))
    var step = 7
    while step >= 0:
        let k = step * 6
        let p = idea_mul(x1 ^ x2, keys[k + 4])
        let q = idea_mul(((x3 ^ x4) + p) & 65535, keys[k + 5])
        let r = (p + q) & 65535
        let a = x1 ^ q
        let c = x2 ^ q
        let b = x3 ^ r
        let d = x4 ^ r
        x1 = idea_mul(a, idea_inverse(keys[k]))
        x2 = (b - keys[k + 1]) & 65535
        x3 = (c - keys[k + 2]) & 65535
        x4 = idea_mul(d, idea_inverse(keys[k + 3]))
        step -= 1
    let recovered = InlineArray[Int, 4](x1, x2, x3, x4)
    for i in range(4):
        output[2 * i] = UInt8(cipher[i] & 255)
        output[2 * i + 1] = UInt8(cipher[i] >> 8)
        output[8 + 2 * i] = UInt8(recovered[i] & 255)
        output[9 + 2 * i] = UInt8(recovered[i] >> 8)
    return 16
