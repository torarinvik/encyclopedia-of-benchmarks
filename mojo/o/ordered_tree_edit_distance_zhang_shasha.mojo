from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

comptime MAX_N = 8
comptime MAX_LEN = 35
comptime INF = 1_000_000

fn post_visit(vertex: Int, labels: InlineArray[Int64, MAX_N], children: InlineArray[Int, MAX_N * MAX_N],
    child_count: InlineArray[Int, MAX_N], mut post_n: Int, mut post_labels: InlineArray[Int64, MAX_N + 1],
    mut leftmost: InlineArray[Int, MAX_N + 1]) -> Int:
    var left = 0
    for k in range(child_count[vertex]):
        let child_left = post_visit(children[vertex * MAX_N + k], labels, children, child_count,
            mut post_n, mut post_labels, mut leftmost)
        if k == 0:
            left = child_left
    post_n += 1
    let node_id = post_n
    post_labels[node_id] = labels[vertex]
    if left == 0:
        leftmost[node_id] = node_id
    else:
        leftmost[node_id] = left
    return leftmost[node_id]

fn read_tree(input: UnsafePointer[Int64, ImmutAnyOrigin], mut position: Int, n: Int,
    mut labels: InlineArray[Int64, MAX_N], mut children: InlineArray[Int, MAX_N * MAX_N],
    mut child_count: InlineArray[Int, MAX_N]) -> Bool:
    for vertex in range(n):
        let label = input[position]
        position += 1
        if label < 0 or label > 3:
            return False
        labels[vertex] = label
    var stack = InlineArray[Int, MAX_N](fill=0)
    var top = 0
    for vertex in range(n):
        let parent = input[position]
        position += 1
        if vertex == 0:
            if parent != -1:
                return False
            stack[0] = 0
            continue
        if parent < 0 or parent >= vertex:
            return False
        while top >= 0 and stack[top] != parent:
            top -= 1
        if top < 0:
            return False
        let parent_index = Int(parent)
        children[parent_index * MAX_N + child_count[parent_index]] = vertex
        child_count[parent_index] += 1
        top += 1
        stack[top] = vertex
    return True

fn distance(labels_a: InlineArray[Int64, MAX_N], children_a: InlineArray[Int, MAX_N * MAX_N],
    count_a: InlineArray[Int, MAX_N], n_a: Int, labels_b: InlineArray[Int64, MAX_N],
    children_b: InlineArray[Int, MAX_N * MAX_N], count_b: InlineArray[Int, MAX_N], n_b: Int) -> Int64:
    var post_a = InlineArray[Int64, MAX_N + 1](fill=0)
    var post_b = InlineArray[Int64, MAX_N + 1](fill=0)
    var left_a = InlineArray[Int, MAX_N + 1](fill=0)
    var left_b = InlineArray[Int, MAX_N + 1](fill=0)
    var post_n_a = 0
    var post_n_b = 0
    _ = post_visit(0, labels_a, children_a, count_a, mut post_n_a, mut post_a, mut left_a)
    _ = post_visit(0, labels_b, children_b, count_b, mut post_n_b, mut post_b, mut left_b)
    var key_a = InlineArray[Int, MAX_N + 1](fill=0)
    var key_b = InlineArray[Int, MAX_N + 1](fill=0)
    for i in range(1, post_n_a + 1):
        key_a[left_a[i]] = i
    for j in range(1, post_n_b + 1):
        key_b[left_b[j]] = j
    var td = InlineArray[Int64, (MAX_N + 1) * (MAX_N + 1)](fill=0)
    for root_a in range(1, post_n_a + 1):
        if key_a[left_a[root_a]] != root_a:
            continue
        for root_b in range(1, post_n_b + 1):
            if key_b[left_b[root_b]] != root_b:
                continue
            let start_a = left_a[root_a]
            let start_b = left_b[root_b]
            var fd = InlineArray[Int64, (MAX_N + 1) * (MAX_N + 1)](fill=INF)
            fd[(start_a - 1) * (MAX_N + 1) + start_b - 1] = 0
            for x in range(start_a, root_a + 1):
                fd[x * (MAX_N + 1) + start_b - 1] = fd[(x - 1) * (MAX_N + 1) + start_b - 1] + 1
            for y in range(start_b, root_b + 1):
                fd[(start_a - 1) * (MAX_N + 1) + y] = fd[(start_a - 1) * (MAX_N + 1) + y - 1] + 1
            for x in range(start_a, root_a + 1):
                for y in range(start_b, root_b + 1):
                    let cell = x * (MAX_N + 1) + y
                    let del = fd[(x - 1) * (MAX_N + 1) + y] + 1
                    let ins = fd[x * (MAX_N + 1) + y - 1] + 1
                    if left_a[x] == start_a and left_b[y] == start_b:
                        var rename = fd[(x - 1) * (MAX_N + 1) + y - 1]
                        if post_a[x] != post_b[y]:
                            rename += 1
                        let best = min(min(del, ins), rename)
                        fd[cell] = best
                        td[cell] = best
                    else:
                        let join = fd[(left_a[x] - 1) * (MAX_N + 1) + left_b[y] - 1] + td[cell]
                        fd[cell] = min(min(del, ins), join)
    return td[post_n_a * (MAX_N + 1) + post_n_b]

@export("ordered_tree_edit_distance_zhang_shasha")
fn ordered_tree_edit_distance_zhang_shasha(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 6 or length > c_size_t(MAX_LEN):
        return -1
    let n1_value = input[0]
    let n2_value = input[1]
    if n1_value < 1 or n1_value > MAX_N or n2_value < 1 or n2_value > MAX_N:
        return -1
    let n1 = Int(n1_value)
    let n2 = Int(n2_value)
    if Int(length) != 2 + 2 * n1 + 2 * n2:
        return -1
    var labels_a = InlineArray[Int64, MAX_N](fill=0)
    var labels_b = InlineArray[Int64, MAX_N](fill=0)
    var children_a = InlineArray[Int, MAX_N * MAX_N](fill=0)
    var children_b = InlineArray[Int, MAX_N * MAX_N](fill=0)
    var count_a = InlineArray[Int, MAX_N](fill=0)
    var count_b = InlineArray[Int, MAX_N](fill=0)
    var position = 2
    if not read_tree(input, mut position, n1, mut labels_a, mut children_a, mut count_a):
        return -1
    if not read_tree(input, mut position, n2, mut labels_b, mut children_b, mut count_b):
        return -1
    return distance(labels_a, children_a, count_a, n1, labels_b, children_b, count_b, n2)
