from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import List
from std.math import exp

fn put_word(mut bytes: List[UInt8], value: Int64):
    var bits = value
    for _ in range(8): bytes.append(UInt8(bits & 255)); bits >>= 8

@export("bilateral_filter")
fn bilateral_filter(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
        output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 5 or length > 1029: return -1
    let hv = input[0]; let wv = input[1]; let kv = input[2]; let sv = input[3]; let iv = input[4]
    if hv < 1 or hv > 32 or wv < 1 or wv > 32 or (kv != 1 and kv != 3 and kv != 5 and kv != 7) or sv < 1 or sv > 1_000_000 or iv < 1 or iv > 1_000_000: return -1
    let h = Int(hv); let w = Int(wv); let pixels = h * w; let radius = Int(kv) // 2
    if length != c_size_t(5 + pixels): return -1
    for i in range(pixels):
        if input[5 + i] < 0 or input[5 + i] > 1_000_000: return -1
    let required = c_size_t(pixels * 8)
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < required: return -2
    var result = List[Int64](capacity=pixels)
    for _ in range(pixels): result.append(0)
    let row_end = h - radius if h >= Int(kv) else radius
    let col_end = w - radius if w >= Int(kv) else radius
    let spatial_var = Float64(sv) / 1_000_000.0
    let intensity_var = Float64(iv) / 1_000_000.0
    for row in range(radius, row_end):
        for col in range(radius, col_end):
            let center = Float64(input[5 + row * w + col]) / 1_000_000.0
            var weighted: Float64 = 0.0; var total: Float64 = 0.0
            for dy in range(-radius, radius + 1):
                for dx in range(-radius, radius + 1):
                    let index = (row + dy) * w + col + dx
                    let sample = Float64(input[5 + index]) / 1_000_000.0
                    let diff = sample - center
                    let spatial = Float64(dx * dx + dy * dy)
                    var weight = exp(-spatial / (2.0 * spatial_var))
                    weight *= exp(-(diff * diff) / (2.0 * intensity_var))
                    weighted += sample * weight; total += weight
            result[row * w + col] = Int64(weighted / total * 1_000_000.0 + 0.5)
    var bytes = List[UInt8](capacity=pixels * 8)
    for v in result: put_word(bytes, v)
    for i in range(pixels * 8): output[i] = bytes[i]
    return Int64(pixels * 8)
