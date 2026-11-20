from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

comptime KQ_MAX_N = 32
comptime KQ_MAX_INPUT = 68
comptime KQ_MAX_DEPTH = 8

fn kq_put_i64_le(output: UnsafePointer[UInt8, MutAnyOrigin], at: Int,
                  value: Int64):
    let bits = UInt64(value)
    for byte_index in range(8):
        output[at + byte_index] = UInt8((bits >> (8 * byte_index)) & 255)

@export("k_quadtree_sampled_point_subdivision")
fn k_quadtree_sampled_point_subdivision(
        input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
        output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3 or length > KQ_MAX_INPUT:
        return -1
    let n_value = input[0]
    let stride_value = input[1]
    let depth_value = input[2]
    if n_value < 1 or n_value > KQ_MAX_N or stride_value < 1 or stride_value > n_value or depth_value < 1 or depth_value > KQ_MAX_DEPTH:
        return -1
    let n = Int(n_value)
    let stride = Int(stride_value)
    let depth = Int(depth_value)
    if length != c_size_t(3 + 2 * n):
        return -1

    let side = Int64(1) << depth
    var keys = InlineArray[UInt32, 32](fill=0)
    for point_index in range(n):
        let x = input[3 + 2 * point_index]
        let y = input[4 + 2 * point_index]
        if x < 0 or y < 0 or x >= side or y >= side:
            return -1
        var key: UInt32 = 0
        for bit in range(depth - 1, -1, -1):
            let x_bit = UInt32((x >> bit) & 1)
            let y_bit = UInt32((y >> bit) & 1)
            key = (key << 2) | (x_bit << 1) | y_bit
        keys[point_index] = key

    for index in range(1, n):
        let value = keys[index]
        var cursor = index
        while cursor > 0 and keys[cursor - 1] > value:
            keys[cursor] = keys[cursor - 1]
            cursor -= 1
        keys[cursor] = value
    for index in range(1, n):
        if keys[index] == keys[index - 1]:
            return -1

    let sample_count = (n - 1) // stride + 1
    var split_depth = InlineArray[Int32, 31](fill=0)
    var split_prefix = InlineArray[UInt32, 31](fill=0)
    var split_count = 0
    for sample_index in range(sample_count - 1):
        let left = keys[sample_index * stride]
        let right = keys[(sample_index + 1) * stride]
        var common_depth = 0
        while common_depth < depth:
            let shift = 2 * (depth - common_depth - 1)
            if ((left >> shift) & 3) != ((right >> shift) & 3):
                break
            common_depth += 1
        var prefix: UInt32 = 0
        if common_depth > 0:
            prefix = left >> (2 * (depth - common_depth))
        var found = 0
        while found < split_count and (split_depth[found] != common_depth or split_prefix[found] != prefix):
            found += 1
        if found == split_count:
            split_depth[split_count] = Int32(common_depth)
            split_prefix[split_count] = prefix
            split_count += 1

    for index in range(1, split_count):
        let depth_value = split_depth[index]
        let prefix_value = split_prefix[index]
        let start = prefix_value << (2 * (depth - Int(depth_value)))
        var cursor = index
        while cursor > 0:
            let previous_depth = Int(split_depth[cursor - 1])
            let previous_start = split_prefix[cursor - 1] << (2 * (depth - previous_depth))
            if previous_start < start or (previous_start == start and previous_depth <= Int(depth_value)):
                break
            split_depth[cursor] = split_depth[cursor - 1]
            split_prefix[cursor] = split_prefix[cursor - 1]
            cursor -= 1
        split_depth[cursor] = depth_value
        split_prefix[cursor] = prefix_value

    let output_bytes = 8 * (1 + 2 * split_count)
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(output_bytes):
        return -2
    kq_put_i64_le(output, 0, Int64(split_count))
    for index in range(split_count):
        kq_put_i64_le(output, 8 * (1 + 2 * index), Int64(split_depth[index]))
        kq_put_i64_le(output, 8 * (2 + 2 * index), Int64(split_prefix[index]))
    return Int64(output_bytes)
