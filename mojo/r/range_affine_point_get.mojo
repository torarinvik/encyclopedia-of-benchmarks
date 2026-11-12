from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

comptime MAX_N = 256
comptime MAX_Q = 256
comptime MAX_BASE = 256
comptime MAX_TREE = 2 * MAX_BASE
comptime MAX_PARSEABLE_INPUT = 2 + MAX_N + 5 * MAX_Q + 1
comptime MODULUS = 998_244_353

fn apply_tag(mul: UnsafePointer[Int64, MutAnyOrigin], add: UnsafePointer[Int64, MutAnyOrigin],
    node: Int, multiplier: Int64, offset: Int64):
    add[node] = (multiplier * add[node] + offset) % MODULUS
    mul[node] = (multiplier * mul[node]) % MODULUS

fn push(mul: UnsafePointer[Int64, MutAnyOrigin], add: UnsafePointer[Int64, MutAnyOrigin], node: Int):
    if mul[node] != 1 or add[node] != 0:
        let multiplier = mul[node]
        let offset = add[node]
        apply_tag(mul, add, 2 * node, multiplier, offset)
        apply_tag(mul, add, 2 * node + 1, multiplier, offset)
        mul[node] = 1
        add[node] = 0

fn range_apply(mul: UnsafePointer[Int64, MutAnyOrigin], add: UnsafePointer[Int64, MutAnyOrigin],
    node: Int, segment_left: Int, segment_right: Int, left: Int, right: Int,
    multiplier: Int64, offset: Int64):
    if right <= segment_left or segment_right <= left:
        return
    if left <= segment_left and segment_right <= right:
        apply_tag(mul, add, node, multiplier, offset)
        return
    push(mul, add, node)
    let middle = segment_left + (segment_right - segment_left) // 2
    range_apply(mul, add, 2 * node, segment_left, middle, left, right, multiplier, offset)
    range_apply(mul, add, 2 * node + 1, middle, segment_right, left, right, multiplier, offset)

fn point_get(mul: UnsafePointer[Int64, MutAnyOrigin], add: UnsafePointer[Int64, MutAnyOrigin],
    initial: UnsafePointer[Int64, ImmutAnyOrigin], node: Int, segment_left: Int,
    segment_right: Int, index: Int) -> Int64:
    if segment_right - segment_left == 1:
        return (mul[node] * initial[index] + add[node]) % MODULUS
    push(mul, add, node)
    let middle = segment_left + (segment_right - segment_left) // 2
    if index < middle:
        return point_get(mul, add, initial, 2 * node, segment_left, middle, index)
    return point_get(mul, add, initial, 2 * node + 1, middle, segment_right, index)

fn store_i64_le(output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int, value: Int64):
    let bits = bitcast[UInt64](value)
    for byte in range(8):
        output[offset + byte] = UInt8((bits >> (byte * 8)) & UInt64(255))

@export("range_affine_point_get")
fn range_affine_point_get(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > c_size_t(MAX_PARSEABLE_INPUT):
        return -1
    let n_value = input[0]
    let q_value = input[1]
    if n_value < 1 or n_value > MAX_N or q_value < 0 or q_value > MAX_Q:
        return -1
    let n = Int(n_value)
    let q = Int(q_value)
    if 2 + n > length:
        return -1
    var initial = InlineArray[Int64, MAX_N](fill=0)
    var kinds = InlineArray[Int64, MAX_Q](fill=0)
    var lefts = InlineArray[Int64, MAX_Q](fill=0)
    var rights = InlineArray[Int64, MAX_Q](fill=0)
    var multipliers = InlineArray[Int64, MAX_Q](fill=0)
    var offsets = InlineArray[Int64, MAX_Q](fill=0)
    for index in range(n):
        initial[index] = input[2 + index]
        if initial[index] < 0 or initial[index] >= MODULUS:
            return -1
    var cursor = 2 + n
    var query_count = 0
    for index in range(q):
        if cursor >= length:
            return -1
        let kind = input[cursor]
        cursor += 1
        kinds[index] = kind
        if kind == 0:
            if cursor + 4 > length:
                return -1
            let left = input[cursor]
            let right = input[cursor + 1]
            let multiplier = input[cursor + 2]
            let offset = input[cursor + 3]
            cursor += 4
            if left < 0 or left >= right or right > n_value or multiplier < 1 or multiplier >= MODULUS or offset < 0 or offset >= MODULUS:
                return -1
            lefts[index] = left
            rights[index] = right
            multipliers[index] = multiplier
            offsets[index] = offset
        elif kind == 1:
            if cursor >= length:
                return -1
            let point = input[cursor]
            cursor += 1
            if point < 0 or point >= n_value:
                return -1
            lefts[index] = point
            query_count += 1
        else:
            return -1
    if cursor != length:
        return -1
    let output_bytes = 8 * query_count
    if output_bytes > 0 and (output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(output_bytes)):
        return -2

    var base = 1
    while base < n:
        base *= 2
    var mul = InlineArray[Int64, MAX_TREE](fill=1)
    var add = InlineArray[Int64, MAX_TREE](fill=0)
    var answer = 0
    for index in range(q):
        if kinds[index] == 0:
            range_apply(mul.unsafe_ptr(), add.unsafe_ptr(), 1, 0, base,
                Int(lefts[index]), Int(rights[index]), multipliers[index], offsets[index])
        else:
            let value = point_get(mul.unsafe_ptr(), add.unsafe_ptr(), initial.unsafe_ptr(),
                1, 0, base, Int(lefts[index]))
            store_i64_le(output, 8 * answer, value)
            answer += 1
    return Int64(output_bytes)
