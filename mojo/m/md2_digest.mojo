from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.math import floor, isfinite
from std.collections import InlineArray

@export("md2_digest")
fn md2_digest(input: UnsafePointer[Float64, ImmutAnyOrigin], length: c_size_t, output: UnsafePointer[Float64, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if length > 63 or (length != 0 and input == UnsafePointer[Float64, ImmutAnyOrigin]()): return -1
    for i in range(Int(length)):
        let x = input[i]
        if not isfinite(x) or x < 0.0 or x > 255.0 or floor(x) != x: return -1
    if output == UnsafePointer[Float64, MutAnyOrigin]() or capacity < 16: return -2
    let s = InlineArray[UInt8, 256](
        41, 46, 67, 201, 162, 216, 124, 1, 61, 54, 84, 161, 236, 240, 6, 19,
        98, 167, 5, 243, 192, 199, 115, 140, 152, 147, 43, 217, 188, 76, 130, 202,
        30, 155, 87, 60, 253, 212, 224, 22, 103, 66, 111, 24, 138, 23, 229, 18,
        190, 78, 196, 214, 218, 158, 222, 73, 160, 251, 245, 142, 187, 47, 238, 122,
        169, 104, 121, 145, 21, 178, 7, 63, 148, 194, 16, 137, 11, 34, 95, 33,
        128, 127, 93, 154, 90, 144, 50, 39, 53, 62, 204, 231, 191, 247, 151, 3,
        255, 25, 48, 179, 72, 165, 181, 209, 215, 94, 146, 42, 172, 86, 170, 198,
        79, 184, 56, 210, 150, 164, 125, 182, 118, 252, 107, 226, 156, 116, 4, 241,
        69, 157, 112, 89, 100, 113, 135, 32, 134, 91, 207, 101, 230, 45, 168, 2,
        27, 96, 37, 173, 174, 176, 185, 246, 28, 70, 97, 105, 52, 64, 126, 15,
        85, 71, 163, 35, 221, 81, 175, 58, 195, 92, 249, 206, 186, 197, 234, 38,
        44, 83, 13, 110, 133, 40, 132, 9, 211, 223, 205, 244, 65, 129, 77, 82,
        106, 220, 55, 200, 108, 193, 171, 250, 36, 225, 123, 8, 12, 189, 177, 74,
        120, 136, 149, 139, 227, 99, 232, 109, 233, 203, 213, 254, 59, 0, 29, 57,
        242, 239, 183, 14, 102, 88, 208, 228, 166, 119, 114, 248, 235, 117, 75, 10,
        49, 68, 80, 180, 143, 237, 31, 26, 219, 153, 141, 51, 159, 17, 131, 20
    )
    let pad = 16 - Int(length) % 16
    let padded_len = Int(length) + pad
    var padded = InlineArray[UInt8, 64](fill=0)
    var checksum = InlineArray[UInt8, 16](fill=0)
    var state = InlineArray[UInt8, 48](fill=0)
    for i in range(Int(length)): padded[i] = UInt8(input[i])
    for i in range(pad): padded[Int(length)+i] = UInt8(pad)
    var last: UInt8 = 0
    for offset in range(0, padded_len, 16):
        for i in range(16):
            let index = Int(padded[offset+i] ^ last)
            checksum[i] ^= s[index]
            last = checksum[i]
    for offset in range(0, padded_len + 1, 16):
        for i in range(16):
            let byte = padded[offset+i] if offset < padded_len else checksum[i]
            state[i+16] = byte
            state[i+32] = state[i] ^ byte
        var temp: UInt8 = 0
        for round in range(18):
            for i in range(48):
                state[i] ^= s[Int(temp)]
                temp = state[i]
            temp = UInt8((Int(temp) + round) % 256)
    var result = InlineArray[Float64, 16](fill=0.0)
    for i in range(16): result[i] = Float64(state[i])
    for i in range(16): output[i] = result[i]
    return 16
