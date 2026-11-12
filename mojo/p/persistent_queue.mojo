from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

alias MAX_Q = 128
alias TREE_BASE = 128
alias TREE_HEIGHT = 7
alias MAX_NODES = 1 + MAX_Q * (TREE_HEIGHT + 1)
alias MAX_PARSEABLE_INPUT = 1 + 3 * MAX_Q + 1
alias MAX_VALUE = 1_000_000_000

fn pq_set(mut node_left: InlineArray[Int, MAX_NODES],
    mut node_right: InlineArray[Int, MAX_NODES],
    mut node_value: InlineArray[Int64, MAX_NODES], mut used: Int,
    root: Int, low: Int, high: Int, position: Int, value: Int64) -> Int:
    let copy = used
    used += 1
    node_left[copy] = node_left[root]
    node_right[copy] = node_right[root]
    node_value[copy] = node_value[root]
    if high - low == 1:
        node_value[copy] = value
        return copy
    let middle = low + (high - low) // 2
    if position < middle:
        let child_root = node_left[root]
        let child = pq_set(mut node_left, mut node_right, mut node_value, mut used,
            child_root, low, middle, position, value)
        node_left[copy] = child
    else:
        let child_root = node_right[root]
        let child = pq_set(mut node_left, mut node_right, mut node_value, mut used,
            child_root, middle, high, position, value)
        node_right[copy] = child
    return copy

fn pq_get(node_left: InlineArray[Int, MAX_NODES],
    node_right: InlineArray[Int, MAX_NODES],
    node_value: InlineArray[Int64, MAX_NODES], root: Int,
    low: Int, high: Int, position: Int) -> Int64:
    if high - low == 1:
        return node_value[root]
    let middle = low + (high - low) // 2
    if position < middle:
        return pq_get(node_left, node_right, node_value, node_left[root], low, middle, position)
    return pq_get(node_left, node_right, node_value, node_right[root], middle, high, position)

fn pq_store(output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int, value: Int64):
    let bits = bitcast[UInt64](value)
    for byte in range(8):
        output[offset + byte] = UInt8((bits >> UInt(8 * byte)) & 255)

@export("persistent_queue")
fn persistent_queue(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > MAX_PARSEABLE_INPUT:
        return -1
    let q_value = input[0]
    if q_value < 1 or q_value > MAX_Q:
        return -1
    let q = Int(q_value)
    var kind = InlineArray[Int64, MAX_Q]()
    var parent = InlineArray[Int64, MAX_Q]()
    var value = InlineArray[Int64, MAX_Q]()
    var version_head = InlineArray[Int, MAX_Q + 1]()
    var version_tail = InlineArray[Int, MAX_Q + 1]()
    var version_size = InlineArray[Int, MAX_Q + 1]()
    var cursor = 1
    var pop_count = 0
    for operation in range(q):
        if cursor + 2 > length:
            return -1
        kind[operation] = input[cursor]
        cursor += 1
        parent[operation] = input[cursor]
        cursor += 1
        if (kind[operation] != 0 and kind[operation] != 1) or parent[operation] < -1 or
            parent[operation] >= Int64(operation):
            return -1
        let base = Int(parent[operation] + 1)
        if kind[operation] == 0:
            if cursor >= length:
                return -1
            value[operation] = input[cursor]
            cursor += 1
            if value[operation] < 0 or value[operation] > MAX_VALUE or version_tail[base] >= TREE_BASE:
                return -1
            version_head[operation + 1] = version_head[base]
            version_tail[operation + 1] = version_tail[base] + 1
            version_size[operation + 1] = version_size[base] + 1
        else:
            if version_size[base] == 0:
                return -1
            version_head[operation + 1] = version_head[base] + 1
            version_tail[operation + 1] = version_tail[base]
            version_size[operation + 1] = version_size[base] - 1
            pop_count += 1
    if cursor != length:
        return -1
    let required = 8 * pop_count
    if required > 0 and (output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(required)):
        return -2

    var node_left = InlineArray[Int, MAX_NODES]()
    var node_right = InlineArray[Int, MAX_NODES]()
    var node_value = InlineArray[Int64, MAX_NODES]()
    var roots = InlineArray[Int, MAX_Q + 1]()
    var answers = InlineArray[Int64, MAX_Q]()
    var used = 1
    var answer_count = 0
    for operation in range(q):
        let base = Int(parent[operation] + 1)
        let version = operation + 1
        if kind[operation] == 0:
            roots[version] = pq_set(mut node_left, mut node_right, mut node_value, mut used,
                roots[base], 0, TREE_BASE, version_tail[base], value[operation])
        else:
            answers[answer_count] = pq_get(node_left, node_right, node_value,
                roots[base], 0, TREE_BASE, version_head[base])
            answer_count += 1
            roots[version] = roots[base]
    for index in range(answer_count):
        pq_store(output, 8 * index, answers[index])
    return Int64(required)
