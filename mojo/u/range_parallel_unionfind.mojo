from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

alias MAX_N = 64
alias MAX_Q = 64
alias MAX_LEVELS = 6
alias MAX_INPUT_VALUES = 2 + MAX_N + 3 * MAX_Q
alias MODULUS = Int64(998244353)
alias LAYER_CELLS = MAX_LEVELS * MAX_N

fn rpu_normalize(value: Int64) -> Int64:
    let reduced = value % MODULUS
    if reduced < 0:
        return reduced + MODULUS
    return reduced

fn rpu_find_root(mut parent: InlineArray[Int, LAYER_CELLS], level: Int, item: Int) -> Int:
    let index = level * MAX_N + item
    if parent[index] != item:
        parent[index] = rpu_find_root(mut parent, level, parent[index])
    return parent[index]

fn rpu_merge_inner(level: Int, left: Int, right: Int,
    mut parent: InlineArray[Int, LAYER_CELLS],
    mut set_size: InlineArray[Int, LAYER_CELLS],
    mut weight: InlineArray[Int64, MAX_N], mut pair_sum: Int64):
    var root_left = rpu_find_root(mut parent, level, left)
    var root_right = rpu_find_root(mut parent, level, right)
    if root_left == root_right:
        return
    var left_index = level * MAX_N + root_left
    var right_index = level * MAX_N + root_right
    if set_size[left_index] < set_size[right_index]:
        let temporary = root_left
        root_left = root_right
        root_right = temporary
        left_index = level * MAX_N + root_left
        right_index = level * MAX_N + root_right
    parent[level * MAX_N + root_right] = root_left
    set_size[left_index] += set_size[right_index]
    if level == 0:
        pair_sum = rpu_normalize(pair_sum + weight[root_left] * weight[root_right])
        weight[root_left] = rpu_normalize(weight[root_left] + weight[root_right])
        return
    let half = 1 << (level - 1)
    rpu_merge_inner(level - 1, left, right, mut parent, mut set_size, mut weight, mut pair_sum)
    rpu_merge_inner(level - 1, left + half, right + half,
        mut parent, mut set_size, mut weight, mut pair_sum)

fn rpu_floor_log2(value: Int) -> Int:
    var level = 0
    var remaining = value
    while remaining > 1:
        remaining >>= 1
        level += 1
    return level

fn rpu_merge_ranges(length: Int, left: Int, right: Int,
    mut parent: InlineArray[Int, LAYER_CELLS],
    mut set_size: InlineArray[Int, LAYER_CELLS],
    mut weight: InlineArray[Int64, MAX_N], mut pair_sum: Int64):
    if length == 0:
        return
    let level = rpu_floor_log2(length - 1)
    let block = 1 << level
    rpu_merge_inner(level, left, right, mut parent, mut set_size, mut weight, mut pair_sum)
    rpu_merge_inner(level, left + length - block, right + length - block,
        mut parent, mut set_size, mut weight, mut pair_sum)

fn rpu_store_i64_le(output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int, value: Int64):
    let bits = bitcast[UInt64](value)
    for byte in range(8):
        output[offset + byte] = UInt8((bits >> UInt(8 * byte)) & 255)

@export("range_parallel_unionfind")
fn range_parallel_unionfind(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 6 or length > MAX_INPUT_VALUES:
        return -1
    let n_value = input[0]
    let q_value = input[1]
    if n_value < 1 or n_value > MAX_N or q_value < 1 or q_value > MAX_Q:
        return -1
    let n = Int(n_value)
    let q = Int(q_value)
    if length != c_size_t(2 + n + 3 * q):
        return -1
    for item in range(n):
        if input[2 + item] < 0 or input[2 + item] >= MODULUS:
            return -1
    let operations_at = 2 + n
    for operation in range(q):
        let position = operations_at + 3 * operation
        let span = input[position]
        let left = input[position + 1]
        let right = input[position + 2]
        if span < 0 or span > n_value or left < 0 or right < 0 or
            left > n_value - span or right > n_value - span:
            return -1
    let required = 8 * q
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(required):
        return -2

    var parent = InlineArray[Int, LAYER_CELLS]()
    var set_size = InlineArray[Int, LAYER_CELLS]()
    var weight = InlineArray[Int64, MAX_N]()
    for level in range(MAX_LEVELS):
        let block = 1 << level
        if block > n:
            break
        for start in range(n - block + 1):
            parent[level * MAX_N + start] = start
            set_size[level * MAX_N + start] = 1
    for item in range(n):
        weight[item] = input[2 + item]
    var pair_sum: Int64 = 0
    for operation in range(q):
        let position = operations_at + 3 * operation
        rpu_merge_ranges(Int(input[position]), Int(input[position + 1]), Int(input[position + 2]),
            mut parent, mut set_size, mut weight, mut pair_sum)
        rpu_store_i64_le(output, 8 * operation, pair_sum)
    return Int64(required)
