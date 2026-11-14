# Independent bounded forward NTT; see package LICENSE.txt for the source notice.
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn ntt_power(base_value: Int64, exponent_value: Int64) -> Int64:
    var base = base_value
    var exponent = exponent_value
    var result: Int64 = 1
    while exponent > 0:
        if (exponent & 1) != 0: result = (result * base) % 998244353
        base = (base * base) % 998244353
        exponent >>= 1
    return result

@export("number_theoretic_transform")
fn number_theoretic_transform(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t, output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 65: return -1
    let count = input[0]
    if count < 1 or count > 64 or (count & (count - 1)) != 0 or length != c_size_t(count + 1): return -1
    let n = Int(count)
    var values = InlineArray[Int64, 64](fill=0)
    for i in range(n):
        let value = input[i + 1]
        if value < 0 or value >= 998244353: return -1
        values[i] = value
    let bytes = 4 * n
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes): return -2
    var j = 0
    for i in range(1, n):
        var bit = n >> 1
        while (j & bit) != 0:
            j ^= bit
            bit >>= 1
        j ^= bit
        if i < j:
            let saved = values[i]
            values[i] = values[j]
            values[j] = saved
    var width = 2
    while width <= n:
        let root = ntt_power(3, 998244352 // Int64(width))
        var base = 0
        while base < n:
            var factor: Int64 = 1
            for k in range(width // 2):
                let a = values[base + k]
                let b = (values[base + k + width // 2] * factor) % 998244353
                values[base + k] = (a + b) % 998244353
                values[base + k + width // 2] = (a - b + 998244353) % 998244353
                factor = (factor * root) % 998244353
            base += width
        width *= 2
    for i in range(n):
        let bits = UInt64(values[i])
        for byte in range(4): output[4 * i + byte] = UInt8((bits >> (8 * byte)) & 255)
    return Int64(bytes)
