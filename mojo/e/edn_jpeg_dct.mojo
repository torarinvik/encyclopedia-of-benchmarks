# Independent fixed-point EDN transform profile. Source attribution and license:
# benchmarks/e/edn_jpeg_dct/NOTICE.txt and LICENSE.txt.
from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn dct_narrow(value: Int) -> Int:
    let bits = value & 65535
    return bits - 65536 if bits >= 32768 else bits

fn dct_line(inout block: InlineArray[Int, 64], factors: InlineArray[Int, 12],
            base: Int, stride: Int, scale: Int, shift: Int):
    var t = InlineArray[Int, 12](fill=0)
    for i in range(4):
        let left = block[base + i * stride]
        let right = block[base + (7 - i) * stride]
        t[i] = left + right
        t[7 - i] = left - right
    t[8] = t[0] + t[3]
    t[9] = t[0] - t[3]
    t[10] = t[1] + t[2]
    t[11] = t[1] - t[2]
    block[base] = dct_narrow((t[8] + t[10]) >> scale)
    block[base + 4 * stride] = dct_narrow((t[8] - t[10]) >> scale)
    let even = dct_narrow(t[11] + t[9]) * factors[10]
    block[base + 2 * stride] = dct_narrow(even + dct_narrow((t[9] * factors[9]) >> shift))
    block[base + 6 * stride] = dct_narrow(even + dct_narrow((t[11] * factors[11]) >> shift))
    let odd0 = dct_narrow(t[4] + t[7]) * factors[2]
    let odd1 = dct_narrow(t[5] + t[6]) * factors[0]
    let left = t[4] + t[6]
    let right = t[5] + t[7]
    let shared = dct_narrow(left + right) * factors[8]
    let left_product = dct_narrow(left) * factors[1] + shared
    let right_product = dct_narrow(right) * factors[3] + shared
    block[base + 7 * stride] = dct_narrow(dct_narrow(t[4] * factors[4] + odd0 + left_product) >> shift)
    block[base + 5 * stride] = dct_narrow(dct_narrow(t[5] * factors[6] + odd1 + right_product) >> shift)
    block[base + 3 * stride] = dct_narrow(dct_narrow(t[6] * factors[5] + odd1 + left_product) >> shift)
    block[base + stride] = dct_narrow(dct_narrow(t[7] * factors[7] + odd0 + right_product) >> shift)

@export("edn_jpeg_dct")
fn edn_jpeg_dct(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length != 76: return -1
    var block = InlineArray[Int, 64](fill=0)
    var factors = InlineArray[Int, 12](fill=0)
    for i in range(64):
        if input[i] < -8 or input[i] > 8: return -1
        block[i] = Int(input[i])
    for i in range(12):
        if input[64 + i] < -32 or input[64 + i] > 31: return -1
        factors[i] = Int(input[64 + i])
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < 512: return -2
    for row in range(8): dct_line(block, factors, row * 8, 1, 0, 13)
    for col in range(8): dct_line(block, factors, col, 8, 3, 16)
    for i in range(64):
        let bits = bitcast[UInt64](Int64(block[i]))
        for byte in range(8): output[8 * i + byte] = UInt8((bits >> UInt(8 * byte)) & 255)
    return 512
