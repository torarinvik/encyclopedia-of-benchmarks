from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

const MAX_TREE_NODES: Int64 = 15
const MAX_TOTAL_NODES = 30
const MAX_PARSEABLE_LENGTH = 93

fn valid_tree(input: UnsafePointer[Int64, ImmutAnyOrigin], offset: Int,
        node_count: Int) -> Bool:
    var visited = InlineArray[Int, 15](fill=0)
    var parents = InlineArray[Int, 15](fill=0)
    var stack = InlineArray[Int, 15](fill=0)
    var top = 1
    var reached = 0
    while top > 0:
        top -= 1
        let node = stack[top]
        if node < 0 or node >= node_count or visited[node] != 0:
            return False
        visited[node] = 1
        reached += 1
        let base = offset + 3 * node
        let left = input[base + 1]
        let right = input[base + 2]
        if left == -1 and right == -1:
            continue
        if left < 0 or right < 0 or left >= node_count or right >= node_count or
            left == right or left == 0 or right == 0:
            return False
        parents[Int(left)] += 1
        parents[Int(right)] += 1
        if parents[Int(left)] != 1 or parents[Int(right)] != 1:
            return False
        stack[top] = Int(right)
        top += 1
        stack[top] = Int(left)
        top += 1
    if reached != node_count or parents[0] != 0:
        return False
    for node in range(1, node_count):
        if parents[node] != 1:
            return False
    return True

@export("same_fringe_leaf_iterator")
fn same_fringe_leaf_iterator(input: UnsafePointer[Int64, ImmutAnyOrigin],
        length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > c_size_t(MAX_PARSEABLE_LENGTH):
        return -1
    let n_a_word = input[0]
    let n_b_word = input[1]
    if n_a_word < 1 or n_a_word > MAX_TREE_NODES or
        n_b_word < 1 or n_b_word > MAX_TREE_NODES:
        return -1
    let n_a = Int(n_a_word)
    let n_b = Int(n_b_word)
    if n_a + n_b > MAX_TOTAL_NODES or length != c_size_t(2 + 3 * (n_a + n_b)):
        return -1
    let offset_a = 2
    let offset_b = 2 + 3 * n_a
    if not valid_tree(input, offset_a, n_a) or not valid_tree(input, offset_b, n_b):
        return -1

    var stack_a = InlineArray[Int, 15](fill=0)
    var stack_b = InlineArray[Int, 15](fill=0)
    var top_a = 1
    var top_b = 1
    while True:
        var have_a = False
        var have_b = False
        var leaf_a: Int64 = 0
        var leaf_b: Int64 = 0
        while top_a > 0 and not have_a:
            top_a -= 1
            let node = stack_a[top_a]
            let base = offset_a + 3 * node
            let left = input[base + 1]
            let right = input[base + 2]
            if left == -1:
                leaf_a = input[base]
                have_a = True
            else:
                stack_a[top_a] = Int(right)
                top_a += 1
                stack_a[top_a] = Int(left)
                top_a += 1
        while top_b > 0 and not have_b:
            top_b -= 1
            let node = stack_b[top_b]
            let base = offset_b + 3 * node
            let left = input[base + 1]
            let right = input[base + 2]
            if left == -1:
                leaf_b = input[base]
                have_b = True
            else:
                stack_b[top_b] = Int(right)
                top_b += 1
                stack_b[top_b] = Int(left)
                top_b += 1
        if not have_a or not have_b:
            if have_a == have_b:
                return 1
            return 0
        if leaf_a != leaf_b:
            return 0
    return -1
