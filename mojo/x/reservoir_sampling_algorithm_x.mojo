from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import List

fn reservoir_x_falling(top: Int64, count: Int) -> Int64:
    var product: Int64 = 1
    for i in range(count): product *= top-Int64(i)
    return product

fn reservoir_x_gcd(a_value: Int64, b_value: Int64) -> Int64:
    var a = a_value
    var b = b_value
    while b != 0:
        let remainder = a % b
        a = b
        b = remainder
    return a

@export("reservoir_sampling_algorithm_x")
fn reservoir_sampling_algorithm_x(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                                  output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3 or length > 49: return -1
    let nv = input[0]
    let kv = input[1]
    if nv < 1 or nv > 16 or kv < 1 or kv > 8: return -1
    let n = Int(nv)
    let k = Int(kv)
    if (k & (k-1)) != 0 or k > n or Int(length) != 2+n+2*(n-k): return -1
    for i in range(n):
        if input[2+i] < -1000000 or input[2+i] > 1000000: return -1
    for i in range(2+n, Int(length)):
        if input[i] < 0 or input[i] > 4294967295: return -1
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(8*k): return -2
    var sample = List[Int64](capacity=8)
    for i in range(k): sample.append(input[2+i])
    var processed = k
    var attempt = 0
    while processed < n:
        let draw = input[2+n+2*attempt]
        let slot_draw = input[2+n+2*attempt+1]
        attempt += 1
        var numerator = reservoir_x_falling(Int64(processed), k)
        var denominator = reservoir_x_falling(Int64(processed+1), k)
        let divisor = reservoir_x_gcd(numerator, denominator)
        numerator //= divisor
        denominator //= divisor
        let max_skip = n-processed-1
        var selected = 0
        var found = False
        for skip in range(max_skip+1):
            if numerator*4294967297 <= (draw+1)*denominator:
                selected = skip
                found = True
                break
            if skip < max_skip:
                let top = Int64(processed+skip+1)
                numerator *= top+1-Int64(k)
                denominator *= top+1
                let reduce_by = reservoir_x_gcd(numerator, denominator)
                numerator //= reduce_by
                denominator //= reduce_by
        if not found: break
        let slot = Int(slot_draw % Int64(k))
        sample[slot] = input[2+processed+selected]
        processed += selected+1
    for i in range(k):
        var bits = UInt64(bitcast[UInt64](sample[i]))
        for j in range(8):
            output[8*i+j] = UInt8(bits & 255)
            bits >>= 8
    return Int64(8*k)
