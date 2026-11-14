# Copyright (c) 2001 Dr Brian Gladman <brg@gladman.uk.net>, Worcester, UK
#
# TERMS
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
# This software is provided 'as is' with no guarantees of correctness or
# fitness for purpose.
#
# Independent bounded inverse AES-256 draft; see package README.
from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn inverse_aes_mul(x: Int, y: Int) -> Int:
    var a = x
    var b = y
    var product = 0
    while b > 0:
        if (b & 1) != 0: product ^= a
        let carry = a & 128
        a = (a << 1) & 255
        if carry != 0: a ^= 27
        b >>= 1
    return product

fn inverse_aes_sbox_source(x: Int) -> Int:
    var inverse = 0
    if x != 0:
        var p = x
        var exponent = 254
        inverse = 1
        while exponent > 0:
            if (exponent & 1) != 0: inverse = inverse_aes_mul(inverse, p)
            p = inverse_aes_mul(p, p)
            exponent >>= 1
    var transformed = inverse ^ 99
    for shift in range(1, 5):
        transformed ^= ((inverse << shift) | (inverse >> (8 - shift))) & 255
    return transformed

@export("cbench_security_rijndael_decrypt")
fn cbench_security_rijndael_decrypt(input: UnsafePointer[Int64, ImmutAnyOrigin],
                                   length: c_size_t,
                                   output: UnsafePointer[UInt8, MutAnyOrigin],
                                   capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length != 48: return -1
    for i in range(48):
        if input[i] < 0 or input[i] > 255: return -1
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < 16: return -2

    var forward = InlineArray[Int, 256](fill=0)
    var inverse = InlineArray[Int, 256](fill=0)
    for i in range(256):
        let mapped = inverse_aes_sbox_source(i)
        forward[i] = mapped
        inverse[mapped] = i
    var key = InlineArray[Int, 240](fill=0)
    for i in range(32): key[i] = Int(input[i])
    var rcon = 1
    for word in range(8, 60):
        var t = InlineArray[Int, 4](fill=0)
        for j in range(4): t[j] = key[4 * (word - 1) + j]
        if word % 8 == 0:
            let first = t[0]
            t[0] = forward[t[1]] ^ rcon
            t[1] = forward[t[2]]
            t[2] = forward[t[3]]
            t[3] = forward[first]
            rcon = inverse_aes_mul(rcon, 2)
        elif word % 8 == 4:
            for j in range(4): t[j] = forward[t[j]]
        for j in range(4): key[4 * word + j] = key[4 * (word - 8) + j] ^ t[j]

    var state = InlineArray[Int, 16](fill=0)
    for i in range(16): state[i] = Int(input[32 + i]) ^ key[224 + i]
    for step in range(14):
        let round = 13 - step
        var shifted = InlineArray[Int, 16](fill=0)
        for column in range(4):
            for row in range(4):
                let source_column = (column + 4 - row) % 4
                let index = 4 * column + row
                shifted[index] = inverse[state[4 * source_column + row]] ^ key[16 * round + index]
        if round == 0:
            for i in range(16): state[i] = shifted[i]
        else:
            for column in range(4):
                let offset = 4 * column
                for row in range(4):
                    let a = shifted[offset + row]
                    let b = shifted[offset + ((row + 1) % 4)]
                    let c = shifted[offset + ((row + 2) % 4)]
                    let d = shifted[offset + ((row + 3) % 4)]
                    state[offset + row] = (inverse_aes_mul(a, 14) ^ inverse_aes_mul(b, 11) ^
                                           inverse_aes_mul(c, 13) ^ inverse_aes_mul(d, 9))
    for i in range(16): output[i] = UInt8(state[i])
    return 16
