from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

comptime MAX_OPERATIONS = 64
comptime NODE_CAPACITY = 129
comptime MISSING: Int64 = -129

struct WbltTree:
    var left: InlineArray[Int, NODE_CAPACITY]
    var right: InlineArray[Int, NODE_CAPACITY]
    var size: InlineArray[Int, NODE_CAPACITY]
    var free_next: InlineArray[Int, NODE_CAPACITY]
    var key: InlineArray[Int64, NODE_CAPACITY]
    var maximum: InlineArray[Int64, NODE_CAPACITY]
    var next_node: Int
    var free_head: Int

    fn __init__(out self):
        self.left = InlineArray[Int, NODE_CAPACITY](fill=0)
        self.right = InlineArray[Int, NODE_CAPACITY](fill=0)
        self.size = InlineArray[Int, NODE_CAPACITY](fill=0)
        self.free_next = InlineArray[Int, NODE_CAPACITY](fill=0)
        self.key = InlineArray[Int64, NODE_CAPACITY](fill=0)
        self.maximum = InlineArray[Int64, NODE_CAPACITY](fill=0)
        self.next_node = 1
        self.free_head = 0

    fn allocate(inout self) -> Int:
        var node = 0
        if self.free_head != 0:
            node = self.free_head
            self.free_head = self.free_next[node]
        else:
            node = self.next_node
            self.next_node += 1
        self.left[node] = 0
        self.right[node] = 0
        self.size[node] = 0
        self.free_next[node] = 0
        self.key[node] = 0
        self.maximum[node] = 0
        return node

    fn release(inout self, node: Int):
        self.left[node] = 0
        self.right[node] = 0
        self.size[node] = 0
        self.key[node] = 0
        self.maximum[node] = 0
        self.free_next[node] = self.free_head
        self.free_head = node

    fn leaf(inout self, value: Int64) -> Int:
        let node = self.allocate()
        self.key[node] = value
        self.maximum[node] = value
        self.size[node] = 1
        return node

    fn join(inout self, a: Int, b: Int) -> Int:
        let node = self.allocate()
        self.left[node] = a
        self.right[node] = b
        self.size[node] = self.size[a] + self.size[b]
        self.maximum[node] = self.maximum[b]
        return node

fn too_heavy(a: Int, b: Int) -> Bool:
    return a > 3 * b

fn merge_nodes(inout tree: WbltTree, a: Int, b: Int) -> Int:
    if a == 0:
        return b
    if b == 0:
        return a
    if too_heavy(tree.size[a], tree.size[b]):
        let x = tree.left[a]
        let y = tree.right[a]
        tree.release(a)
        let merged = merge_nodes(tree, y, b)
        let joined = tree.join(x, merged)
        let left_size = tree.size[tree.left[joined]]
        let right_size = tree.size[tree.right[joined]]
        if too_heavy(left_size, right_size) or too_heavy(right_size, left_size):
            let p = tree.left[joined]
            let q = tree.right[joined]
            tree.release(joined)
            return merge_nodes(tree, p, q)
        return joined
    if too_heavy(tree.size[b], tree.size[a]):
        let x = tree.left[b]
        let y = tree.right[b]
        tree.release(b)
        let merged = merge_nodes(tree, a, x)
        let joined = tree.join(merged, y)
        let left_size = tree.size[tree.left[joined]]
        let right_size = tree.size[tree.right[joined]]
        if too_heavy(left_size, right_size) or too_heavy(right_size, left_size):
            let p = tree.left[joined]
            let q = tree.right[joined]
            tree.release(joined)
            return merge_nodes(tree, p, q)
        return joined
    let joined = tree.join(a, b)
    let left_size = tree.size[tree.left[joined]]
    let right_size = tree.size[tree.right[joined]]
    if too_heavy(left_size, right_size) or too_heavy(right_size, left_size):
        let p = tree.left[joined]
        let q = tree.right[joined]
        tree.release(joined)
        return merge_nodes(tree, p, q)
    return joined

fn rebalance(inout tree: WbltTree, node: Int) -> Int:
    if tree.size[node] == 1:
        return node
    let a = tree.left[node]
    let b = tree.right[node]
    if too_heavy(tree.size[a], tree.size[b]) or too_heavy(tree.size[b], tree.size[a]):
        tree.release(node)
        return merge_nodes(tree, a, b)
    return node

fn insert_key(inout tree: WbltTree, node: Int, value: Int64) -> Int:
    if node == 0:
        return tree.leaf(value)
    if tree.size[node] == 1:
        if value <= tree.key[node]:
            let added = tree.leaf(value)
            return tree.join(added, node)
        let added = tree.leaf(value)
        return tree.join(node, added)
    let a = tree.left[node]
    if value <= tree.maximum[a]:
        tree.left[node] = insert_key(tree, a, value)
    else:
        let b = tree.right[node]
        tree.right[node] = insert_key(tree, b, value)
    let left = tree.left[node]
    let right = tree.right[node]
    tree.size[node] = tree.size[left] + tree.size[right]
    tree.maximum[node] = tree.maximum[right]
    return rebalance(tree, node)

fn remove_one(inout tree: WbltTree, node: Int, value: Int64, inout removed: Bool) -> Int:
    removed = False
    if node == 0:
        return 0
    if tree.size[node] == 1:
        if tree.key[node] != value:
            return node
        tree.release(node)
        removed = True
        return 0
    let a = tree.left[node]
    if value <= tree.maximum[a]:
        tree.left[node] = remove_one(tree, a, value, removed)
    else:
        let b = tree.right[node]
        tree.right[node] = remove_one(tree, b, value, removed)
    if not removed:
        return node
    let left = tree.left[node]
    let right = tree.right[node]
    if left == 0 or right == 0:
        let child = left if left != 0 else right
        tree.release(node)
        return child
    tree.size[node] = tree.size[left] + tree.size[right]
    tree.maximum[node] = tree.maximum[right]
    return rebalance(tree, node)

fn rank_less(tree: WbltTree, node: Int, value: Int64) -> Int64:
    if node == 0:
        return 0
    if tree.size[node] == 1:
        return 1 if tree.key[node] < value else 0
    let a = tree.left[node]
    if value <= tree.maximum[a]:
        return rank_less(tree, a, value)
    return Int64(tree.size[a]) + rank_less(tree, tree.right[node], value)

fn kth(tree: WbltTree, node_input: Int, index_input: Int64) -> Int64:
    if node_input == 0 or index_input >= Int64(tree.size[node_input]):
        return MISSING
    var node = node_input
    var index = index_input
    while tree.size[node] != 1:
        let a = tree.left[node]
        if index < Int64(tree.size[a]):
            node = a
        else:
            index -= Int64(tree.size[a])
            node = tree.right[node]
    return tree.key[node]

fn predecessor(tree: WbltTree, node: Int, value: Int64) -> Int64:
    if node == 0:
        return MISSING
    if tree.size[node] == 1:
        return tree.key[node] if tree.key[node] < value else MISSING
    let a = tree.left[node]
    if value <= tree.maximum[a]:
        return predecessor(tree, a, value)
    let answer = predecessor(tree, tree.right[node], value)
    return tree.maximum[a] if answer == MISSING else answer

fn successor(tree: WbltTree, node: Int, value: Int64) -> Int64:
    if node == 0:
        return MISSING
    if tree.size[node] == 1:
        return tree.key[node] if tree.key[node] > value else MISSING
    let a = tree.left[node]
    if value < tree.maximum[a]:
        return successor(tree, a, value)
    return successor(tree, tree.right[node], value)

@export("weight_balanced_leaf_tree_order_statistics")
fn weight_balanced_leaf_tree_order_statistics(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > 130:
        return -1
    let q = input[0]
    if q < 0 or q > MAX_OPERATIONS:
        return -1
    if length != c_size_t(1 + 2 * q):
        return -1
    for index in range(Int(q)):
        let operation = input[1 + 2 * index]
        let argument = input[2 + 2 * index]
        if operation < 0 or operation > 5:
            return -1
        if operation == 3:
            if argument < 0 or argument >= MAX_OPERATIONS:
                return -1
        elif argument < -128 or argument > 127:
            return -1
    var tree = WbltTree()
    var root = 0
    var checksum: Int64 = 0
    for index in range(Int(q)):
        let operation = input[1 + 2 * index]
        let argument = input[2 + 2 * index]
        if operation == 0:
            root = insert_key(tree, root, argument)
        elif operation == 1:
            var removed = False
            root = remove_one(tree, root, argument, removed)
        else:
            var answer: Int64 = 0
            if operation == 2:
                answer = rank_less(tree, root, argument)
            elif operation == 3:
                answer = kth(tree, root, argument)
            elif operation == 4:
                answer = predecessor(tree, root, argument)
            else:
                answer = successor(tree, root, argument)
            checksum += Int64(index + 1) * (answer - MISSING)
    return checksum
