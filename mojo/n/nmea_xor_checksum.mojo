from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("nmea_xor_checksum")
fn nmea_xor_checksum(input: UnsafePointer[Int64, ImmutAnyOrigin],
                     length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length == 0 or length > 78:
        return -1
    let payload_length = input[0]
    if payload_length < 0 or payload_length > 76:
        return -1
    if Int(length) != Int(payload_length) + 1:
        return -1
    var checksum: Int64 = 0
    for i in range(1, Int(length)):
        let byte = input[i]
        if byte < 0 or byte > 127:
            return -1
        checksum ^= byte
    return checksum
