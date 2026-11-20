# Bounded power-of-two Sqrt Tree with O(1) layer selection.
from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

comptime MAX_N = 64
comptime MAX_Q = 64
comptime MAX_LEVELS = 4
comptime MAX_INPUT = 195
comptime VALUE_LIMIT = 1000000000
comptime INF = 9223372036854775807

@export("sqrt_tree_constant_time")
fn sqrt_tree_constant_time(
        input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
        output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < c_size_t(2) or length > c_size_t(MAX_INPUT):
        return -1
    let n_value = input[0]
    let q_value = input[1]
    if n_value < 1 or n_value > MAX_N or q_value < 0 or q_value > MAX_Q: return -1
    let n = Int(n_value)
    let q = Int(q_value)
    if length != c_size_t(2 + n + 2 * q): return -1
    for i in range(n):
        if input[2 + i] < -VALUE_LIMIT or input[2 + i] > VALUE_LIMIT: return -1
    for query in range(q):
        let left = input[2 + n + 2 * query]
        let right = input[3 + n + 2 * query]
        if left < 0 or right < left or right >= n_value: return -1
    let required = 8 * q
    if capacity < c_size_t(required) or (required > 0 and output == UnsafePointer[UInt8, MutAnyOrigin]()):
        return -2

    var values = InlineArray[Int64, 64](fill=0)
    var prefix = InlineArray[Int64, 256](fill=0)
    var suffix = InlineArray[Int64, 256](fill=0)
    var between = InlineArray[Int64, 256](fill=0)
    var floor_log = InlineArray[Int, 65](fill=0)
    var segment_bits = InlineArray[Int, 4](fill=0)
    var block_bits = InlineArray[Int, 4](fill=0)
    var layer_for_diff = InlineArray[Int, 7](fill=-1)
    var padded = 1
    while padded < n: padded *= 2
    for i in range(n): values[i] = input[2 + i]
    for i in range(n, padded): values[i] = INF
    for i in range(2, padded + 1): floor_log[i] = floor_log[i // 2] + 1
    var layer_count = 0
    var bits = floor_log[padded]
    while bits > 1:
        let level = layer_count
        layer_count += 1
        let bbits = (bits + 1) // 2
        segment_bits[level] = bits
        block_bits[level] = bbits
        for bit in range(bbits, bits): layer_for_diff[bit] = level
        bits = bbits

    for level in range(layer_count):
        let sbits = segment_bits[level]
        let bbits = block_bits[level]
        let segment_size = 1 << sbits
        let block_size = 1 << bbits
        let block_count = segment_size // block_size
        let pair_count = block_count * block_count
        for base in range(0, padded, segment_size):
            let segment_index = base // segment_size
            for block in range(block_count):
                let start = base + block * block_size
                let end = start + block_size
                prefix[level * MAX_N + start] = values[start]
                for i in range(start + 1, end):
                    let slot = level * MAX_N + i
                    prefix[slot] = min(prefix[slot - 1], values[i])
                suffix[level * MAX_N + end - 1] = values[end - 1]
                var i = end - 1
                while i > start:
                    i -= 1
                    let slot = level * MAX_N + i
                    suffix[slot] = min(values[i], suffix[slot + 1])
            for left_block in range(block_count):
                var aggregate = INF
                for right_block in range(left_block, block_count):
                    let start = base + right_block * block_size
                    aggregate = min(aggregate, suffix[level * MAX_N + start])
                    let slot = segment_index * pair_count + left_block * block_count + right_block
                    between[level * MAX_N + slot] = aggregate

    for query in range(q):
        let left = Int(input[2 + n + 2 * query])
        let right = Int(input[3 + n + 2 * query])
        var answer: Int64
        if left == right:
            answer = values[left]
        else:
            let bit = floor_log[left ^ right]
            if bit == 0:
                answer = min(values[left], values[right])
            else:
                let level = layer_for_diff[bit]
                let segment_size = 1 << segment_bits[level]
                let block_size = 1 << block_bits[level]
                let base = (left // segment_size) * segment_size
                let segment_index = base // segment_size
                let block_count = segment_size // block_size
                let left_block = (left - base) // block_size
                let right_block = (right - base) // block_size
                answer = min(suffix[level * MAX_N + left], prefix[level * MAX_N + right])
                if left_block + 1 < right_block:
                    let pair_count = block_count * block_count
                    let slot = segment_index * pair_count + (left_block + 1) * block_count + right_block - 1
                    answer = min(answer, between[level * MAX_N + slot])
        var result_bits = bitcast[UInt64](answer)
        for byte in range(8):
            output[8 * query + byte] = UInt8(result_bits & UInt64(255))
            result_bits = result_bits >> 8
    return Int64(required)
