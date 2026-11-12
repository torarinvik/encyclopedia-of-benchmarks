from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import List

@export("prefix_sum_of_binomial_coefficient")
fn prefix_sum_of_binomial_coefficient(
        input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
        output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3 or length > 34:
        return -1
    let count_value = input[0]
    if count_value < 1 or count_value > 16: return -1
    let count = Int(count_value)
    if length != c_size_t(1 + 2 * count): return -1
    var ns = List[Int64](capacity=count)
    var ks = List[Int64](capacity=count)
    for query in range(count):
        let n = input[1 + 2 * query]
        let k = input[2 + 2 * query]
        if n < 0 or n > 128 or k < 0 or k > n: return -1
        ns.append(n)
        ks.append(k)
    let output_length = 4 * count
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(output_length):
        return -2

    let modulus = Int64(998244353)
    var inverse = List[Int64](capacity=129)
    for _ in range(129): inverse.append(0)
    inverse[1] = 1
    for value in range(2, 129):
        let v = Int64(value)
        let remainder = Int(modulus % v)
        inverse[value] = modulus - (modulus // v) * inverse[remainder] % modulus
    for query in range(count):
        var coefficient = Int64(1)
        var prefix = Int64(1)
        for step in range(Int(ks[query])):
            let i = Int64(step)
            coefficient = coefficient * (ns[query] - i) % modulus
            coefficient = coefficient * inverse[step + 1] % modulus
            prefix = (prefix + coefficient) % modulus
        let residue = UInt32(prefix)
        let offset = 4 * query
        output[offset] = UInt8(residue & 255)
        output[offset + 1] = UInt8((residue >> 8) & 255)
        output[offset + 2] = UInt8((residue >> 16) & 255)
        output[offset + 3] = UInt8((residue >> 24) & 255)
    return Int64(output_length)
