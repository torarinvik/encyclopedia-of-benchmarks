# Copyright 2018 Embedded Microprocessor Benchmark Consortium (EEMBC).
# Original author Shay Gal-on. Licensed under Apache-2.0; see package notice.
from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn matrix_sum(values: List[Int64], clip: Int64) -> Int64:
    var accumulator = Int64(0)
    var previous = Int64(0)
    var result = Int64(0)
    for i in range(9):
        let current = values[i]
        accumulator += current
        if accumulator > clip:
            result += 10
            accumulator = 0
        elif current > previous:
            result += 1
        previous = current
    return result

fn crc_word(word: Int64, initial: Int64) -> Int64:
    var crc = initial
    for byte in range(2):
        var value = (word >> (8 * byte)) & 255
        for _ in range(8):
            let feedback = (value ^ crc) & 1
            value = value >> 1
            if feedback != 0:
                crc = ((crc ^ 0x4002) >> 1) | 0x8000
            else:
                crc = crc >> 1
    return crc

@export("coremark_matrix_manipulation")
fn coremark_matrix_manipulation(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                                output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length != 19: return -1
    let value = input[0]
    if value < 0 or value > 15: return -1
    var a = List[Int64](capacity=9)
    var b = List[Int64](capacity=9)
    var c = List[Int64](capacity=9)
    for i in range(9):
        if input[1+i] < 0 or input[1+i] > 127 or input[10+i] < 0 or input[10+i] > 127: return -1
        a.append(input[1+i] + value)
        b.append(input[10+i])
        c.append(0)
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < 112: return -2
    let clip = value - 4096
    var sums = List[Int64](capacity=4)
    for i in range(9): c[i] = a[i] * value
    sums.append(matrix_sum(c, clip))
    for i in range(3):
        c[i] = 0
        for j in range(3): c[i] += a[3*i+j] * b[j]
    sums.append(matrix_sum(c, clip))
    for i in range(3):
        for j in range(3):
            c[3*i+j] = 0
            for k in range(3): c[3*i+j] += a[3*i+k] * b[3*k+j]
    sums.append(matrix_sum(c, clip))
    for i in range(3):
        for j in range(3):
            c[3*i+j] = 0
            for k in range(3):
                let product = a[3*i+k] * b[3*k+j]
                c[3*i+j] += ((product >> 2) & 15) * ((product >> 5) & 127)
    sums.append(matrix_sum(c, clip))
    var crc = Int64(0)
    for i in range(4): crc = crc_word(sums[i], crc)
    var result = List[Int64](capacity=14)
    result.append(crc)
    for i in range(4): result.append(sums[i])
    for i in range(9): result.append(a[i] - value)
    for i in range(14):
        for byte in range(8): output[8*i+byte] = UInt8((result[i] >> (8*byte)) & 255)
    return 112
