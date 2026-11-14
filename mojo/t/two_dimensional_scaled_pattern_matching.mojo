from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("two_dimensional_scaled_pattern_matching")
fn two_dimensional_scaled_pattern_matching(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t, output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 6 or length > 186: return -1
    let hv = input[0]; let wv = input[1]; let phv = input[2]; let pwv = input[3]; let p = input[4]; let q = input[5]
    if hv < 1 or hv > 12 or wv < 1 or wv > 12 or phv < 1 or phv > 6 or pwv < 1 or pwv > 6 or q < 1 or q > 8 or p < q or p > 2 * q: return -1
    let h = Int(hv); let w = Int(wv); let ph = Int(phv); let pw = Int(pwv)
    if length != c_size_t(6 + h * w + ph * pw): return -1
    var text = InlineArray[Int64, 144](fill=0)
    var pattern = InlineArray[Int64, 36](fill=0)
    for i in range(h * w):
        let value = input[6 + i]
        if value < 0 or value > 255: return -1
        text[i] = value
    for i in range(ph * pw):
        let value = input[6 + h * w + i]
        if value < 0 or value > 255: return -1
        pattern[i] = value
    var fields = InlineArray[Int64, 289](fill=0)
    var used = 1
    for row in range(h):
        for col in range(w):
            if p * phv > q * Int64(h - row) or p * pwv > q * Int64(w - col): continue
            var matched = True
            for y in range(h - row):
                if Int64(2 * y + 1) * q >= 2 * p * phv: continue
                let py = Int((Int64(2 * y + 1) * q) // (2 * p))
                for x in range(w - col):
                    if Int64(2 * x + 1) * q >= 2 * p * pwv: continue
                    let px = Int((Int64(2 * x + 1) * q) // (2 * p))
                    if text[(row + y) * w + col + x] != pattern[py * pw + px]:
                        matched = False
                        break
                if not matched: break
            if matched:
                fields[used] = Int64(row)
                fields[used + 1] = Int64(col)
                used += 2
    fields[0] = Int64((used - 1) // 2)
    let bytes = 8 * used
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes): return -2
    for i in range(used):
        var bits = UInt64(fields[i])
        for byte in range(8):
            output[8 * i + byte] = UInt8(bits & 255)
            bits >>= 8
    return Int64(bytes)
