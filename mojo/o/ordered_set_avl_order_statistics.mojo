from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

comptime MAX_ITEMS = 32
comptime MAX_OPS = 32
comptime MAX_KEY = 1000

struct AvlTree:
    var keys: InlineArray[Int64, 65]
    var heights: InlineArray[Int32, 65]
    var sizes: InlineArray[Int32, 65]
    var left: InlineArray[Int32, 65]
    var right: InlineArray[Int32, 65]
    var used: Int

fn node_height(inout tree: AvlTree, node: Int) -> Int:
    if node == 0: return 0
    return Int(tree.heights[node])

fn node_size(inout tree: AvlTree, node: Int) -> Int:
    if node == 0: return 0
    return Int(tree.sizes[node])

fn refresh(inout tree: AvlTree, node: Int):
    let lh = node_height(tree, Int(tree.left[node]))
    let rh = node_height(tree, Int(tree.right[node]))
    tree.heights[node] = Int32(max(lh, rh) + 1)
    tree.sizes[node] = Int32(node_size(tree, Int(tree.left[node])) + node_size(tree, Int(tree.right[node])) + 1)

fn rotate_right(inout tree: AvlTree, root: Int) -> Int:
    let pivot = Int(tree.left[root])
    tree.left[root] = tree.right[pivot]
    tree.right[pivot] = Int32(root)
    refresh(tree, root)
    refresh(tree, pivot)
    return pivot

fn rotate_left(inout tree: AvlTree, root: Int) -> Int:
    let pivot = Int(tree.right[root])
    tree.right[root] = tree.left[pivot]
    tree.left[pivot] = Int32(root)
    refresh(tree, root)
    refresh(tree, pivot)
    return pivot

fn rebalance(inout tree: AvlTree, root: Int) -> Int:
    refresh(tree, root)
    let difference = node_height(tree, Int(tree.left[root])) - node_height(tree, Int(tree.right[root]))
    if difference > 1:
        let child = Int(tree.left[root])
        if node_height(tree, Int(tree.left[child])) < node_height(tree, Int(tree.right[child])):
            tree.left[root] = Int32(rotate_left(tree, child))
        return rotate_right(tree, root)
    if difference < -1:
        let child = Int(tree.right[root])
        if node_height(tree, Int(tree.right[child])) < node_height(tree, Int(tree.left[child])):
            tree.right[root] = Int32(rotate_right(tree, child))
        return rotate_left(tree, root)
    return root

fn insert_key(inout tree: AvlTree, root: Int, key: Int64) -> Int:
    if root == 0:
        tree.used += 1
        let node = tree.used
        tree.keys[node] = key
        tree.heights[node] = 1
        tree.sizes[node] = 1
        return node
    if key < tree.keys[root]:
        tree.left[root] = Int32(insert_key(tree, Int(tree.left[root]), key))
    elif key > tree.keys[root]:
        tree.right[root] = Int32(insert_key(tree, Int(tree.right[root]), key))
    else:
        return root
    return rebalance(tree, root)

fn minimum_node(inout tree: AvlTree, root_input: Int) -> Int:
    var root = root_input
    while tree.left[root] != 0: root = Int(tree.left[root])
    return root

fn erase_key(inout tree: AvlTree, root: Int, key: Int64) -> Int:
    if root == 0: return 0
    if key < tree.keys[root]:
        tree.left[root] = Int32(erase_key(tree, Int(tree.left[root]), key))
    elif key > tree.keys[root]:
        tree.right[root] = Int32(erase_key(tree, Int(tree.right[root]), key))
    elif tree.left[root] == 0:
        return Int(tree.right[root])
    elif tree.right[root] == 0:
        return Int(tree.left[root])
    else:
        let next = minimum_node(tree, Int(tree.right[root]))
        tree.keys[root] = tree.keys[next]
        tree.right[root] = Int32(erase_key(tree, Int(tree.right[root]), tree.keys[next]))
    return rebalance(tree, root)

fn kth(inout tree: AvlTree, root_input: Int, rank: Int64) -> Int64:
    if rank < 1 or rank > Int64(node_size(tree, root_input)): return -1
    var root = root_input
    var current_rank = Int(rank)
    while root != 0:
        let left_count = node_size(tree, Int(tree.left[root]))
        if current_rank == left_count + 1: return tree.keys[root]
        if current_rank <= left_count: root = Int(tree.left[root])
        else:
            current_rank -= left_count + 1
            root = Int(tree.right[root])
    return -1

fn count_le(inout tree: AvlTree, root_input: Int, key: Int64) -> Int64:
    var root = root_input
    var count = 0
    while root != 0:
        if tree.keys[root] <= key:
            count += node_size(tree, Int(tree.left[root])) + 1
            root = Int(tree.right[root])
        else: root = Int(tree.left[root])
    return Int64(count)

fn predecessor(inout tree: AvlTree, root_input: Int, key: Int64) -> Int64:
    var root = root_input
    var answer: Int64 = -1
    while root != 0:
        if tree.keys[root] <= key:
            answer = tree.keys[root]
            root = Int(tree.right[root])
        else: root = Int(tree.left[root])
    return answer

fn successor(inout tree: AvlTree, root_input: Int, key: Int64) -> Int64:
    var root = root_input
    var answer: Int64 = -1
    while root != 0:
        if tree.keys[root] >= key:
            answer = tree.keys[root]
            root = Int(tree.left[root])
        else: root = Int(tree.right[root])
    return answer

@export("ordered_set_avl_order_statistics")
fn ordered_set_avl_order_statistics(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 99: return -1
    let n64 = input[0]
    let q64 = input[1]
    if n64 < 0 or n64 > MAX_ITEMS or q64 < 0 or q64 > MAX_OPS or length != c_size_t(2 + n64 + 2 * q64): return -1
    let n = Int(n64)
    let q = Int(q64)
    for i in range(n):
        let key = input[2 + i]
        if key < 0 or key > MAX_KEY or (i > 0 and input[1 + i] >= key): return -1
    for i in range(q):
        let op = input[2 + n + 2 * i]
        let key = input[3 + n + 2 * i]
        if op < 0 or op > 5 or key < 0 or key > MAX_KEY or (op == 2 and key < 1): return -1
    var tree = AvlTree()
    var root = 0
    for i in range(n): root = insert_key(tree, root, input[2 + i])
    var checksum: Int64 = 0
    var query_index: Int64 = 0
    for i in range(q):
        let op = input[2 + n + 2 * i]
        let key = input[3 + n + 2 * i]
        if op == 0: root = insert_key(tree, root, key)
        elif op == 1: root = erase_key(tree, root, key)
        else:
            var answer: Int64 = -1
            if op == 2: answer = kth(tree, root, key)
            elif op == 3: answer = count_le(tree, root, key)
            elif op == 4: answer = predecessor(tree, root, key)
            else: answer = successor(tree, root, key)
            query_index += 1
            checksum += query_index * (answer + 1)
    return checksum
