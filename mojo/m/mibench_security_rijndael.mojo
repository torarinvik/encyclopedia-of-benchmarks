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
# Independent algebraic AES-256 draft; see package README for provenance.
from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn rijndael_mul(a: Int, b: Int) -> Int:
    var left = a
    var right = b
    var result = 0
    while right != 0:
        if (right & 1) != 0: result ^= left
        let high = left & 128
        left = (left << 1) & 255
        if high != 0: left ^= 27
        right >>= 1
    return result

fn rijndael_sbox(value: Int) -> Int:
    var inverse = 0
    if value != 0:
        var base = value
        var exponent = 254
        inverse = 1
        while exponent != 0:
            if (exponent & 1) != 0: inverse = rijndael_mul(inverse, base)
            base = rijndael_mul(base, base)
            exponent >>= 1
    var result = inverse ^ 99
    for shift in range(1, 5):
        result ^= ((inverse << shift) | (inverse >> (8 - shift))) & 255
    return result

@export("mibench_security_rijndael")
fn mibench_security_rijndael(input: UnsafePointer[Int64, ImmutAnyOrigin],
                             length: c_size_t,
                             output: UnsafePointer[UInt8, MutAnyOrigin],
                             capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length != 48: return -1
    for i in range(48):
        if input[i] < 0 or input[i] > 255: return -1
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < 16: return -2

    var substitution = InlineArray[Int, 256](fill=0)
    for i in range(256): substitution[i] = rijndael_sbox(i)
    var expanded = InlineArray[Int, 240](fill=0)
    for i in range(32): expanded[i] = Int(input[i])
    var constant = 1
    for word in range(8, 60):
        var temp = InlineArray[Int, 4](fill=0)
        for i in range(4): temp[i] = expanded[4 * (word - 1) + i]
        if word % 8 == 0:
            let first = temp[0]
            temp[0] = substitution[temp[1]] ^ constant
            temp[1] = substitution[temp[2]]
            temp[2] = substitution[temp[3]]
            temp[3] = substitution[first]
            constant = rijndael_mul(constant, 2)
        elif word % 8 == 4:
            for i in range(4): temp[i] = substitution[temp[i]]
        for i in range(4):
            expanded[4 * word + i] = expanded[4 * (word - 8) + i] ^ temp[i]

    var state = InlineArray[Int, 16](fill=0)
    for i in range(16): state[i] = Int(input[32 + i]) ^ expanded[i]
    for round in range(1, 15):
        var shifted = InlineArray[Int, 16](fill=0)
        for column in range(4):
            for row in range(4):
                shifted[4 * column + row] = substitution[state[4 * ((column + row) % 4) + row]]
        if round != 14:
            for column in range(4):
                let pos = 4 * column
                let a = shifted[pos]
                let b = shifted[pos + 1]
                let c = shifted[pos + 2]
                let d = shifted[pos + 3]
                state[pos] = rijndael_mul(a, 2) ^ rijndael_mul(b, 3) ^ c ^ d
                state[pos + 1] = a ^ rijndael_mul(b, 2) ^ rijndael_mul(c, 3) ^ d
                state[pos + 2] = a ^ b ^ rijndael_mul(c, 2) ^ rijndael_mul(d, 3)
                state[pos + 3] = rijndael_mul(a, 3) ^ b ^ c ^ rijndael_mul(d, 2)
        else:
            for i in range(16): state[i] = shifted[i]
        for i in range(16): state[i] ^= expanded[16 * round + i]
    for i in range(16): output[i] = UInt8(state[i])
    return 16
