from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
from std.collections import List

comptime MAX_NODE_COUNT = 257
comptime MAX_NODE_KEYS = 15
comptime MAX_NODE_CHILDREN = 16
comptime MAX_KEY_COUNT = 256
comptime MAX_OPERATIONS = 511
comptime OFFSET = 1000000
comptime HASH_MOD = 1000000007

fn split_child(mut keys: List[Int64], mut children: List[Int], mut counts: List[Int], mut leaves: List[Bool], mut used: Int, parent: Int, child_index: Int, degree: Int) -> Bool:
    if used >= MAX_NODE_COUNT: return False
    let child = children[parent * MAX_NODE_CHILDREN + child_index]
    let sibling = used
    used += 1
    leaves[sibling] = leaves[child]
    counts[sibling] = degree - 1
    for i in range(degree - 1):
        keys[sibling * MAX_NODE_KEYS + i] = keys[child * MAX_NODE_KEYS + degree + i]
    if not leaves[child]:
        for i in range(degree):
            children[sibling * MAX_NODE_CHILDREN + i] = children[child * MAX_NODE_CHILDREN + degree + i]
    let parent_count = counts[parent]
    for i in range(parent_count + 1, child_index + 1, -1):
        children[parent * MAX_NODE_CHILDREN + i] = children[parent * MAX_NODE_CHILDREN + i - 1]
    children[parent * MAX_NODE_CHILDREN + child_index + 1] = sibling
    for i in range(parent_count, child_index, -1):
        keys[parent * MAX_NODE_KEYS + i] = keys[parent * MAX_NODE_KEYS + i - 1]
    keys[parent * MAX_NODE_KEYS + child_index] = keys[child * MAX_NODE_KEYS + degree - 1]
    counts[child] = degree - 1
    counts[parent] = parent_count + 1
    return True

fn insert_non_full(mut keys: List[Int64], mut children: List[Int], mut counts: List[Int], mut leaves: List[Bool], mut used: Int, node: Int, key: Int64, degree: Int) -> Bool:
    var index = counts[node]
    if leaves[node]:
        while index > 0 and key <= keys[node * MAX_NODE_KEYS + index - 1]:
            keys[node * MAX_NODE_KEYS + index] = keys[node * MAX_NODE_KEYS + index - 1]
            index -= 1
        keys[node * MAX_NODE_KEYS + index] = key
        counts[node] += 1
        return True
    while index > 0 and key <= keys[node * MAX_NODE_KEYS + index - 1]:
        index -= 1
    let child = children[node * MAX_NODE_CHILDREN + index]
    if counts[child] == 2 * degree - 1:
        if not split_child(keys, children, counts, leaves, used, node, index, degree): return False
        if keys[node * MAX_NODE_KEYS + index] < key: index += 1
    return insert_non_full(keys, children, counts, leaves, used, children[node * MAX_NODE_CHILDREN + index], key, degree)

fn insert_key(mut keys: List[Int64], mut children: List[Int], mut counts: List[Int], mut leaves: List[Bool], mut used: Int, mut root: Int, key: Int64, degree: Int) -> Bool:
    if counts[root] == 2 * degree - 1:
        if used + 2 > MAX_NODE_COUNT: return False
        let old_root = root
        let new_root = used
        used += 1
        leaves[new_root] = False
        children[new_root * MAX_NODE_CHILDREN] = old_root
        root = new_root
        if not split_child(keys, children, counts, leaves, used, new_root, 0, degree): return False
    return insert_non_full(keys, children, counts, leaves, used, root, key, degree)

fn search_key(keys: List[Int64], children: List[Int], counts: List[Int], leaves: List[Bool], root: Int, key: Int64) -> Bool:
    var node = root
    while True:
        var index = 0
        while index < counts[node] and key > keys[node * MAX_NODE_KEYS + index]: index += 1
        if index < counts[node] and key == keys[node * MAX_NODE_KEYS + index]: return True
        if leaves[node]: return False
        node = children[node * MAX_NODE_CHILDREN + index]
    return False

fn inorder(keys: List[Int64], children: List[Int], counts: List[Int], leaves: List[Bool], root: Int) -> List[Int64]:
    var output = List[Int64](capacity=MAX_KEY_COUNT)
    var node_stack = List[Int](capacity=32)
    var position_stack = List[Int](capacity=32)
    node_stack.append(root)
    position_stack.append(0)
    while len(node_stack) > 0:
        let top = len(node_stack) - 1
        let node = node_stack[top]
        let count = counts[node]
        if leaves[node]:
            if position_stack[top] == count:
                _ = node_stack.pop()
                _ = position_stack.pop()
                continue
            let value = keys[node * MAX_NODE_KEYS + position_stack[top]]
            position_stack[top] += 1
            output.append(value)
        elif position_stack[top] > 2 * count:
            _ = node_stack.pop()
            _ = position_stack.pop()
        else:
            let position = position_stack[top]
            position_stack[top] += 1
            if position % 2 == 0:
                node_stack.append(children[node * MAX_NODE_CHILDREN + position / 2])
                position_stack.append(0)
            else:
                output.append(keys[node * MAX_NODE_KEYS + position / 2])
    return output

@export("b_tree_benchmark")
fn b_tree_benchmark(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 1024: return -1
    let degree_value = input[0]
    let operation_value = input[1]
    if degree_value < 2 or degree_value > 8 or operation_value < 0 or operation_value > MAX_OPERATIONS: return -1
    let degree = Int(degree_value)
    let operations = Int(operation_value)
    if length != c_size_t(2 + 2 * operations): return -1
    var keys = List[Int64](capacity=MAX_NODE_COUNT * MAX_NODE_KEYS)
    var children = List[Int](capacity=MAX_NODE_COUNT * MAX_NODE_CHILDREN)
    var counts = List[Int](capacity=MAX_NODE_COUNT)
    var leaves = List[Bool](capacity=MAX_NODE_COUNT)
    for _ in range(MAX_NODE_COUNT * MAX_NODE_KEYS): keys.append(0)
    for _ in range(MAX_NODE_COUNT * MAX_NODE_CHILDREN): children.append(0)
    for _ in range(MAX_NODE_COUNT):
        counts.append(0)
        leaves.append(False)
    leaves[0] = True
    var used = 1
    var root = 0
    var key_count = 0
    var checksum: Int64 = 0
    for operation in range(operations):
        let opcode = input[2 + 2 * operation]
        let payload = input[3 + 2 * operation]
        var observed: Int64 = 0
        if opcode == 0:
            if payload < -OFFSET or payload > OFFSET or key_count == MAX_KEY_COUNT: return -1
            if not insert_key(keys, children, counts, leaves, used, root, payload, degree): return -1
            key_count += 1
            observed = 1
        elif opcode == 1:
            if payload < -OFFSET or payload > OFFSET: return -1
            observed = 1 if search_key(keys, children, counts, leaves, root, payload) else 0
        elif opcode == 2:
            if payload != 0: return -1
            let ordered = inorder(keys, children, counts, leaves, root)
            var hash: Int64 = 0
            for i in range(len(ordered)):
                hash = (hash * 257 + ordered[i] + 1000001) % HASH_MOD
            observed = hash
        else:
            return -1
        checksum += Int64(operation + 1) * (observed + OFFSET)
    let ordered = inorder(keys, children, counts, leaves, root)
    for i in range(len(ordered)):
        checksum += Int64(operations + i + 1) * (ordered[i] + OFFSET)
    return checksum
