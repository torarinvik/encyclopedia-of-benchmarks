from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

fn crc8_reverse(x_input: UInt8) -> UInt8:
    var x = x_input
    x = (x >> 4) | (x << 4)
    x = ((x & 204) >> 2) | ((x & 51) << 2)
    return ((x & 170) >> 1) | ((x & 85) << 1)

@export("crc8_model")
fn crc8_model(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 6 or length > 100007: return -1
    let poly = input[0]
    let init = input[1]
    let ref_in = input[2]
    let ref_out = input[3]
    let xor_out = input[4]
    let count = input[5]
    if poly < 0 or poly > 255 or init < 0 or init > 255 or xor_out < 0 or xor_out > 255 or (ref_in != 0 and ref_in != 1) or (ref_out != 0 and ref_out != 1) or count < 0 or count > 100001 or length != 6 + count: return -1
    var crc = UInt8(init)
    for i in range(count):
        let raw = input[6 + i]
        if raw < 0 or raw > 255: return -1
        var byte = UInt8(raw)
        if ref_in == 1: byte = crc8_reverse(byte)
        crc ^= byte
        for bit in range(8):
            let top = crc & 128
            crc = crc << 1
            if top != 0: crc ^= UInt8(poly)
    if ref_out == 1: crc = crc8_reverse(crc)
    return Int64(crc ^ UInt8(xor_out))
