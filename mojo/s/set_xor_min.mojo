from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

alias MAX_Q = 64
alias MAX_BITS = 30
alias MAX_NODES = 1 + MAX_BITS * MAX_Q
alias MAX_INPUT_VALUES = 1 + 2 * MAX_Q
alias CHILD_CELLS = 2 * MAX_NODES

fn sxm_find_or_create_child(mut children: InlineArray[Int, CHILD_CELLS],
    mut node_count: Int, node: Int, direction: Int) -> Int:
    let slot = node * 2 + direction
    var child = children[slot]
    if child < 0:
        child = node_count
        node_count += 1
        children[child * 2] = -1
        children[child * 2 + 1] = -1
        children[slot] = child
    return child

fn sxm_insert(mut children: InlineArray[Int, CHILD_CELLS],
    mut count: InlineArray[Int, MAX_NODES], mut node_count: Int, value: UInt32):
    var path = InlineArray[Int, MAX_BITS + 1]()
    var node = 0
    for depth in range(MAX_BITS):
        let bit = MAX_BITS - 1 - depth
        let direction = Int((value >> UInt(bit)) & 1)
        node = sxm_find_or_create_child(mut children, mut node_count, node, direction)
        path[depth + 1] = node
    if count[node] != 0:
        return
    for depth in range(MAX_BITS + 1):
        count[path[depth]] += 1

fn sxm_remove(children: InlineArray[Int, CHILD_CELLS],
    mut count: InlineArray[Int, MAX_NODES], value: UInt32):
    var path = InlineArray[Int, MAX_BITS + 1]()
    var node = 0
    for depth in range(MAX_BITS):
        let bit = MAX_BITS - 1 - depth
        let direction = Int((value >> UInt(bit)) & 1)
        node = children[node * 2 + direction]
        if node < 0:
            return
        path[depth + 1] = node
    if count[node] == 0:
        return
    for depth in range(MAX_BITS + 1):
        count[path[depth]] -= 1

fn sxm_minimum_xor(children: InlineArray[Int, CHILD_CELLS],
    count: InlineArray[Int, MAX_NODES], value: UInt32) -> UInt32:
    var node = 0
    var result: UInt32 = 0
    var bit = MAX_BITS
    while bit > 0:
        bit -= 1
        let preferred = Int((value >> UInt(bit)) & 1)
        let child = children[node * 2 + preferred]
        if child >= 0 and count[child] > 0:
            node = child
        else:
            result |= UInt32(1) << UInt(bit)
            node = children[node * 2 + (preferred ^ 1)]
    return result

fn sxm_store_i64_le(output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int, value: Int64):
    let bits = bitcast[UInt64](value)
    for byte in range(8):
        output[offset + byte] = UInt8((bits >> UInt(8 * byte)) & 255)

@export("set_xor_min")
fn set_xor_min(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3 or length > MAX_INPUT_VALUES:
        return -1
    let q_value = input[0]
    if q_value < 1 or q_value > MAX_Q:
        return -1
    let q = Int(q_value)
    if length != c_size_t(1 + 2 * q):
        return -1
    for operation in range(q):
        let offset = 1 + 2 * operation
        if input[offset] < 0 or input[offset] > 2 or input[offset + 1] < 0 or
            input[offset + 1] >= (Int64(1) << MAX_BITS):
            return -1

    var children = InlineArray[Int, CHILD_CELLS]()
    var count = InlineArray[Int, MAX_NODES]()
    for node in range(MAX_NODES):
        children[node * 2] = -1
        children[node * 2 + 1] = -1
    var node_count = 1
    var answers = InlineArray[Int64, MAX_Q]()
    var answer_count = 0
    for operation in range(q):
        let offset = 1 + 2 * operation
        let kind = input[offset]
        let value = UInt32(input[offset + 1])
        if kind == 0:
            sxm_insert(mut children, mut count, mut node_count, value)
        elif kind == 1:
            sxm_remove(children, mut count, value)
        else:
            if count[0] == 0:
                return -1
            answers[answer_count] = Int64(sxm_minimum_xor(children, count, value))
            answer_count += 1
    let required = 8 * answer_count
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(required):
        return -2
    for index in range(answer_count):
        sxm_store_i64_le(output, 8 * index, answers[index])
    return Int64(required)
