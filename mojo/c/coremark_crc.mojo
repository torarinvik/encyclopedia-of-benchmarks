# Copyright 2018 Embedded Microprocessor Benchmark Consortium (EEMBC).
# Licensed under Apache-2.0; original author Shay Gal-on.
# Independently written recurrence; see the package's license notice.
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

fn crc_byte(value: Int64, initial: Int64) -> Int64:
    var data = value
    var crc = initial
    for _ in range(8):
        let feedback = (data ^ crc) & 1
        data = data >> 1
        if feedback != 0:
            crc = ((crc ^ 0x4002) >> 1) | 0x8000
        else:
            crc = crc >> 1
    return crc

@export("coremark_crc")
fn coremark_crc(values: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if values == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 4 or length > 49: return -1
    let count = values[0]
    if count < 1 or count > 16 or length != c_size_t(1 + 3 * count): return -1
    var total = Int64(0)
    for i in range(Int(count)):
        let tag = values[1 + 3 * i]
        let seed = values[2 + 3 * i]
        let value = values[3 + 3 * i]
        if seed < 0 or seed > 65535: return -1
        var width = 0
        if tag == 0 and value >= 0 and value <= 255:
            width = 1
        elif tag == 1 and value >= 0 and value <= 65535:
            width = 2
        elif tag == 2 and value >= 0 and value <= 4294967295:
            width = 4
        elif tag == 3 and value >= -32768 and value <= 32767:
            width = 2
        else:
            return -1
        var crc = seed
        for byte in range(width):
            crc = crc_byte((value >> (8 * byte)) & 255, crc)
        total += Int64(i + 1) * crc
    return total
