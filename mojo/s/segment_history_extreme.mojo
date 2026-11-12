from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

alias MAX_N = 32
alias MAX_Q = 32
alias TREE_SIZE = 4 * MAX_N
alias MAX_INPUT = 2 + MAX_N + 4 * MAX_Q
alias VALUE_LIMIT = Int64(1000)

struct ShNode(Copyable):
    var maximum: Int64 = 0
    var history_maximum: Int64 = 0
    var add: Int64 = 0
    var add_peak: Int64 = 0
    var set_value: Int64 = 0
    var set_peak: Int64 = 0
    var has_set: Bool = False

fn sh_max(a: Int64, b: Int64) -> Int64:
    if a > b: return a
    return b

fn sh_apply_add_summary(mut tree: InlineArray[ShNode, TREE_SIZE], node: Int, net: Int64, peak: Int64):
    tree[node].history_maximum = sh_max(tree[node].history_maximum, tree[node].maximum + peak)
    tree[node].maximum += net
    if tree[node].has_set:
        tree[node].set_peak = sh_max(tree[node].set_peak, tree[node].set_value + peak)
        tree[node].set_value += net
    else:
        tree[node].add_peak = sh_max(tree[node].add_peak, tree[node].add + peak)
        tree[node].add += net

fn sh_apply_add(mut tree: InlineArray[ShNode, TREE_SIZE], node: Int, delta: Int64):
    if tree[node].has_set:
        tree[node].set_peak = sh_max(tree[node].set_peak, tree[node].set_value + delta)
        tree[node].set_value += delta
    else:
        tree[node].add_peak = sh_max(tree[node].add_peak, tree[node].add + delta)
        tree[node].add += delta
    tree[node].history_maximum = sh_max(tree[node].history_maximum, tree[node].maximum + delta)
    tree[node].maximum += delta

fn sh_apply_set_summary(mut tree: InlineArray[ShNode, TREE_SIZE], node: Int, value: Int64, peak: Int64):
    tree[node].history_maximum = sh_max(tree[node].history_maximum, peak)
    tree[node].maximum = value
    if tree[node].has_set:
        tree[node].set_peak = sh_max(tree[node].set_peak, peak)
    else:
        tree[node].has_set = True
        tree[node].set_peak = peak
    tree[node].set_value = value

fn sh_apply_set(mut tree: InlineArray[ShNode, TREE_SIZE], node: Int, value: Int64):
    tree[node].history_maximum = sh_max(tree[node].history_maximum, value)
    tree[node].maximum = value
    if tree[node].has_set:
        tree[node].set_peak = sh_max(tree[node].set_peak, value)
    else:
        tree[node].has_set = True
        tree[node].set_peak = value
    tree[node].set_value = value

fn sh_push(mut tree: InlineArray[ShNode, TREE_SIZE], node: Int):
    let parent = tree[node]
    if parent.add != 0 or parent.add_peak != 0:
        sh_apply_add_summary(mut tree, 2 * node, parent.add, parent.add_peak)
        sh_apply_add_summary(mut tree, 2 * node + 1, parent.add, parent.add_peak)
        tree[node].add = 0
        tree[node].add_peak = 0
    if parent.has_set:
        sh_apply_set_summary(mut tree, 2 * node, parent.set_value, parent.set_peak)
        sh_apply_set_summary(mut tree, 2 * node + 1, parent.set_value, parent.set_peak)
        tree[node].has_set = False
        tree[node].set_value = 0
        tree[node].set_peak = 0

fn sh_pull(mut tree: InlineArray[ShNode, TREE_SIZE], node: Int):
    tree[node].maximum = sh_max(tree[2 * node].maximum, tree[2 * node + 1].maximum)
    tree[node].history_maximum = sh_max(tree[2 * node].history_maximum, tree[2 * node + 1].history_maximum)

fn sh_build(mut tree: InlineArray[ShNode, TREE_SIZE], input: UnsafePointer[Int64, ImmutAnyOrigin],
    offset: Int, node: Int, left: Int, right: Int):
    if right - left == 1:
        tree[node].maximum = input[offset + left]
        tree[node].history_maximum = input[offset + left]
        return
    let middle = left + (right - left) // 2
    sh_build(mut tree, input, offset, 2 * node, left, middle)
    sh_build(mut tree, input, offset, 2 * node + 1, middle, right)
    sh_pull(mut tree, node)

fn sh_update(mut tree: InlineArray[ShNode, TREE_SIZE], node: Int, left: Int, right: Int,
    ql: Int, qr: Int, assignment: Bool, value: Int64):
    if ql <= left and right <= qr:
        if assignment: sh_apply_set(mut tree, node, value)
        else: sh_apply_add(mut tree, node, value)
        return
    sh_push(mut tree, node)
    let middle = left + (right - left) // 2
    if ql < middle: sh_update(mut tree, 2 * node, left, middle, ql, qr, assignment, value)
    if middle < qr: sh_update(mut tree, 2 * node + 1, middle, right, ql, qr, assignment, value)
    sh_pull(mut tree, node)

fn sh_query(mut tree: InlineArray[ShNode, TREE_SIZE], node: Int, left: Int, right: Int,
    ql: Int, qr: Int, historical: Bool) -> Int64:
    if ql <= left and right <= qr:
        if historical: return tree[node].history_maximum
        return tree[node].maximum
    sh_push(mut tree, node)
    let middle = left + (right - left) // 2
    var answer: Int64 = -1000000000000
    if ql < middle: answer = sh_query(mut tree, 2 * node, left, middle, ql, qr, historical)
    if middle < qr: answer = sh_max(answer, sh_query(mut tree, 2 * node + 1, middle, right, ql, qr, historical))
    return answer

fn sh_write_i64(output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int, value: Int64):
    let bits = value.bitcast[UInt64]()
    for byte in range(8): output[offset + byte] = ((bits >> (8 * byte)) & 255).cast[UInt8]()

@export("segment_history_extreme")
fn segment_history_extreme(
    input: UnsafePointer[Int64, ImmutAnyOrigin], input_length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], output_capacity: c_size_t,
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or input_length < 2 or input_length > c_size_t(MAX_INPUT): return -1
    let n_value = input[0]
    let q_value = input[1]
    if n_value < 1 or n_value > MAX_N or q_value < 0 or q_value > MAX_Q: return -1
    let n = Int(n_value)
    let q = Int(q_value)
    if Int(input_length) != 2 + n + 4 * q: return -1
    for i in range(n):
        if input[2 + i] < -VALUE_LIMIT or input[2 + i] > VALUE_LIMIT: return -1
    let operation_offset = 2 + n
    for i in range(q):
        let offset = operation_offset + 4 * i
        let op = input[offset]
        let left = input[offset + 1]
        let right = input[offset + 2]
        let arg = input[offset + 3]
        if op < 0 or op > 3 or left < 0 or right <= left or right > n_value: return -1
        if op < 2:
            if arg < -VALUE_LIMIT or arg > VALUE_LIMIT: return -1
        elif arg != 0: return -1

    var tree = InlineArray[ShNode, TREE_SIZE]()
    var staged = InlineArray[Int64, MAX_Q]()
    sh_build(mut tree, input, 2, 1, 0, n)
    var answer_count = 0
    for i in range(q):
        let offset = operation_offset + 4 * i
        let op = Int(input[offset])
        let left = Int(input[offset + 1])
        let right = Int(input[offset + 2])
        let arg = input[offset + 3]
        if op < 2:
            sh_update(mut tree, 1, 0, n, left, right, op == 0, arg)
        else:
            staged[answer_count] = sh_query(mut tree, 1, 0, n, left, right, op == 3)
            answer_count += 1
    let output_bytes = 8 * answer_count
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or output_capacity < c_size_t(output_bytes): return -2
    for i in range(answer_count): sh_write_i64(output, 8 * i, staged[i])
    return Int64(output_bytes)
