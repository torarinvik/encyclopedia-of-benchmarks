from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

comptime MOD = 1_000_000_007
comptime MAX_N = 32
comptime MAX_Q = 32
comptime MAX_LEVELS = 5

@fieldwise_init
struct DSTAffine(Copyable):
    var a: Int64
    var b: Int64

fn dst_combine(left: DSTAffine, right: DSTAffine) -> DSTAffine:
    return DSTAffine(right.a * left.a % MOD,
                     (right.a * left.b + right.b) % MOD)

fn dst_put(output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int, value: Int64):
    let bits = bitcast[UInt64](value)
    for byte in range(8):
        output[offset + byte] = UInt8((bits >> (8 * byte)) & UInt64(255))

@export("disjoint_sparse_table_affine_composition")
fn disjoint_sparse_table_affine_composition(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t,
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 130:
        return -1
    let n_value = input[0]
    let q_value = input[1]
    if n_value < 1 or n_value > MAX_N or q_value < 1 or q_value > MAX_Q: return -1
    let n = Int(n_value)
    let q = Int(q_value)
    if length != c_size_t(2 + 2 * n + 2 * q): return -1

    var maps = InlineArray[DSTAffine, MAX_N]()
    var left = InlineArray[Int, MAX_Q]()
    var right = InlineArray[Int, MAX_Q]()
    var cursor = 2
    for index in range(n):
        let a = input[cursor]
        let b = input[cursor + 1]
        cursor += 2
        if a < 0 or a >= MOD or b < 0 or b >= MOD: return -1
        maps[index] = DSTAffine(a, b)
    for query in range(q):
        let lo = input[cursor]
        let hi = input[cursor + 1]
        cursor += 2
        if lo < 0 or lo > hi or hi >= n_value: return -1
        left[query] = Int(lo)
        right[query] = Int(hi)

    let output_bytes = q * 16
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(output_bytes):
        return -2

    var table = InlineArray[DSTAffine, MAX_LEVELS * MAX_N]()
    var levels = 0
    var span = 1
    while span < n:
        levels += 1
        span *= 2
    for level in range(levels):
        let half = 1 << level
        let width = half * 2
        var start = 0
        while start < n:
            let middle = min(start + half, n)
            let ending = min(start + width, n)
            if middle > start:
                table[level * MAX_N + middle - 1] = maps[middle - 1]
                var index = middle - 1
                while index > start:
                    table[level * MAX_N + index - 1] = dst_combine(
                        maps[index - 1], table[level * MAX_N + index])
                    index -= 1
            if middle < ending:
                table[level * MAX_N + middle] = maps[middle]
                for index in range(middle + 1, ending):
                    table[level * MAX_N + index] = dst_combine(
                        table[level * MAX_N + index - 1], maps[index])
            start += width

    for query in range(q):
        var answer: DSTAffine
        if left[query] == right[query]:
            answer = maps[left[query]]
        else:
            var difference = left[query] ^ right[query]
            var level = 0
            while difference > 1:
                difference >>= 1
                level += 1
            answer = dst_combine(table[level * MAX_N + left[query]],
                                 table[level * MAX_N + right[query]])
        dst_put(output, query * 16, answer.a)
        dst_put(output, query * 16 + 8, answer.b)
    return Int64(output_bytes)
