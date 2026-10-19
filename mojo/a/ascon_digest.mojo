from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import List

fn ascon_rotr(value: UInt64, shift: UInt) -> UInt64:
    return (value >> shift) | (value << (64 - shift))

fn ascon_permute(mut state: List[UInt64], rounds: Int):
    var constants = List[UInt64](length=12, fill=0)
    constants[0] = 0xf0
    constants[1] = 0xe1
    constants[2] = 0xd2
    constants[3] = 0xc3
    constants[4] = 0xb4
    constants[5] = 0xa5
    constants[6] = 0x96
    constants[7] = 0x87
    constants[8] = 0x78
    constants[9] = 0x69
    constants[10] = 0x5a
    constants[11] = 0x4b
    var first = 0
    if rounds == 8:
        first = 4
    for round in range(first, 12):
        let x0 = state[0]
        let x1 = state[1]
        let x2 = state[2]
        let x3 = state[3]
        let x4 = state[4]
        let c = constants[round]
        let t0 = x0 ^ x1 ^ x2 ^ x3 ^ c ^ (x1 & (x0 ^ x2 ^ x4 ^ c))
        let t1 = x0 ^ x2 ^ x3 ^ x4 ^ c ^ ((x1 ^ x2 ^ c) & (x1 ^ x3))
        let t2 = x1 ^ x2 ^ x4 ^ c ^ (x3 & x4)
        let t3 = x0 ^ x1 ^ x2 ^ c ^ ((~x0) & (x3 ^ x4))
        let t4 = x1 ^ x3 ^ x4 ^ ((x0 ^ x4) & x1)
        state[0] = t0 ^ ascon_rotr(t0, 19) ^ ascon_rotr(t0, 28)
        state[1] = t1 ^ ascon_rotr(t1, 39) ^ ascon_rotr(t1, 61)
        state[2] = ~(t2 ^ ascon_rotr(t2, 1) ^ ascon_rotr(t2, 6))
        state[3] = t3 ^ ascon_rotr(t3, 10) ^ ascon_rotr(t3, 17)
        state[4] = t4 ^ ascon_rotr(t4, 7) ^ ascon_rotr(t4, 41)

fn ascon_store_be(output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int, value: UInt64):
    for byte in range(8):
        output[offset + byte] = UInt8((value >> UInt(56 - 8 * byte)) & 255)

@export("ascon_digest")
fn ascon_digest(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t, output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2:
        return -1
    let variant = input[0]
    let message_length = input[1]
    if (variant != 0 and variant != 1) or message_length < 0 or message_length > 4096 or length != c_size_t(message_length + 2):
        return -1
    for i in range(Int(message_length)):
        if input[i + 2] < 0 or input[i + 2] > 255:
            return -1
    var state = List[UInt64](length=5, fill=0)
    if variant == 0:
        state[0] = 0xee9398aadb67f03d
        state[1] = 0x8bb21831c60f1002
        state[2] = 0xb48a92db98d5da62
        state[3] = 0x43189921b8f8e3e8
        state[4] = 0x348fa5c9d525e140
    else:
        state[0] = 0x01470194fc6528a6
        state[1] = 0x738ec38ac0adffa7
        state[2] = 0x2ec8e3296c76384c
        state[3] = 0xd6f6a54d7f52377d
        state[4] = 0xa13c42a223be8d87
    var rounds = 12
    if variant == 1:
        rounds = 8
    let complete = Int(message_length) - Int(message_length) % 8
    for offset in range(0, complete, 8):
        var word: UInt64 = 0
        for byte in range(8):
            word = (word << 8) | UInt64(input[offset + byte + 2])
        state[0] ^= word
        ascon_permute(state, rounds)
    let tail = Int(message_length) - complete
    var final_word = UInt64(0x80) << UInt(56 - 8 * tail)
    for byte in range(tail):
        final_word |= UInt64(input[complete + byte + 2]) << UInt(56 - 8 * byte)
    state[0] ^= final_word
    ascon_permute(state, 12)
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < 32:
        return -2
    for block in range(4):
        ascon_store_be(output, block * 8, state[0])
        if block != 3:
            ascon_permute(state, rounds)
    return 32
