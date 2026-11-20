from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

comptime MAX_OPERATIONS = 128
comptime MAX_NODES = 128
comptime MISSING: Int64 = -1025

struct SbtTree:
    var keys: InlineArray[Int64, 129]
    var sizes: InlineArray[Int, 129]
    var left: InlineArray[Int, 129]
    var right: InlineArray[Int, 129]
    var used: Int

    fn __init__(out self):
        self.keys = InlineArray[Int64, 129](fill=0)
        self.sizes = InlineArray[Int, 129](fill=0)
        self.left = InlineArray[Int, 129](fill=0)
        self.right = InlineArray[Int, 129](fill=0)
        self.used = 0

fn subtree_size(inout tree: SbtTree, node: Int) -> Int:
    if node == 0:
        return 0
    return tree.sizes[node]

fn update_size(inout tree: SbtTree, node: Int):
    tree.sizes[node] = subtree_size(tree, tree.left[node]) + subtree_size(tree, tree.right[node]) + 1

fn rotate_left(inout tree: SbtTree, root: Int) -> Int:
    let pivot = tree.right[root]
    tree.right[root] = tree.left[pivot]
    tree.left[pivot] = root
    update_size(tree, root)
    update_size(tree, pivot)
    return pivot

fn rotate_right(inout tree: SbtTree, root: Int) -> Int:
    let pivot = tree.left[root]
    tree.left[root] = tree.right[pivot]
    tree.right[pivot] = root
    update_size(tree, root)
    update_size(tree, pivot)
    return pivot

fn maintain(inout tree: SbtTree, root_input: Int) -> Int:
    if root_input == 0:
        return 0
    var root = root_input
    let left_child = tree.left[root]
    let right_child = tree.right[root]
    if subtree_size(tree, left_child) < subtree_size(tree, tree.left[right_child]):
        tree.right[root] = rotate_right(tree, right_child)
        root = rotate_left(tree, root)
        tree.left[root] = maintain(tree, tree.left[root])
        tree.right[root] = maintain(tree, tree.right[root])
        return maintain(tree, root)
    if subtree_size(tree, left_child) < subtree_size(tree, tree.right[right_child]):
        root = rotate_left(tree, root)
        tree.left[root] = maintain(tree, tree.left[root])
        return maintain(tree, root)
    if subtree_size(tree, right_child) < subtree_size(tree, tree.left[left_child]):
        root = rotate_right(tree, root)
        tree.right[root] = maintain(tree, tree.right[root])
        return maintain(tree, root)
    if subtree_size(tree, right_child) < subtree_size(tree, tree.right[left_child]):
        tree.left[root] = rotate_left(tree, left_child)
        root = rotate_right(tree, root)
        tree.left[root] = maintain(tree, tree.left[root])
        tree.right[root] = maintain(tree, tree.right[root])
        return maintain(tree, root)
    return root

fn contains(inout tree: SbtTree, root_input: Int, key: Int64) -> Bool:
    var root = root_input
    while root != 0:
        if key < tree.keys[root]:
            root = tree.left[root]
        elif key > tree.keys[root]:
            root = tree.right[root]
        else:
            return True
    return False

fn insert_new(inout tree: SbtTree, root: Int, key: Int64) -> Int:
    if root == 0:
        tree.used += 1
        let node = tree.used
        tree.keys[node] = key
        tree.sizes[node] = 1
        return node
    if key < tree.keys[root]:
        tree.left[root] = insert_new(tree, tree.left[root], key)
    else:
        tree.right[root] = insert_new(tree, tree.right[root], key)
    update_size(tree, root)
    return maintain(tree, root)

fn rank_less(inout tree: SbtTree, root_input: Int, key: Int64) -> Int64:
    var root = root_input
    var rank = 0
    while root != 0:
        if key <= tree.keys[root]:
            root = tree.left[root]
        else:
            rank += subtree_size(tree, tree.left[root]) + 1
            root = tree.right[root]
    return Int64(rank)

fn kth(inout tree: SbtTree, root_input: Int, index_input: Int64) -> Int64:
    if index_input < 0 or index_input >= Int64(subtree_size(tree, root_input)):
        return MISSING
    var root = root_input
    var index = Int(index_input)
    while root != 0:
        let left_size = subtree_size(tree, tree.left[root])
        if index == left_size:
            return tree.keys[root]
        if index < left_size:
            root = tree.left[root]
        else:
            index -= left_size + 1
            root = tree.right[root]
    return MISSING

fn predecessor(inout tree: SbtTree, root_input: Int, key: Int64) -> Int64:
    var root = root_input
    var answer = MISSING
    while root != 0:
        if tree.keys[root] < key:
            answer = tree.keys[root]
            root = tree.right[root]
        else:
            root = tree.left[root]
    return answer

fn successor(inout tree: SbtTree, root_input: Int, key: Int64) -> Int64:
    var root = root_input
    var answer = MISSING
    while root != 0:
        if tree.keys[root] > key:
            answer = tree.keys[root]
            root = tree.left[root]
        else:
            root = tree.right[root]
    return answer

@export("size_balanced_ordered_set")
fn size_balanced_ordered_set(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > 257:
        return -1
    let operation_count_value = input[0]
    if operation_count_value < 0 or operation_count_value > MAX_OPERATIONS:
        return -1
    let operation_count = Int(operation_count_value)
    if length != c_size_t(1 + 2 * operation_count):
        return -1

    for index in range(operation_count):
        let operation = input[1 + 2 * index]
        let argument = input[2 + 2 * index]
        if operation < 0 or operation > 4:
            return -1
        if operation == 2:
            if argument < 0 or argument > 127:
                return -1
        elif argument < -1024 or argument > 1023:
            return -1

    var tree = SbtTree()
    var root = 0
    var checksum: Int64 = 0
    for index in range(operation_count):
        let operation = input[1 + 2 * index]
        let argument = input[2 + 2 * index]
        var answer: Int64 = 0
        if operation == 0:
            if not contains(tree, root, argument):
                root = insert_new(tree, root, argument)
            continue
        if operation == 1:
            answer = rank_less(tree, root, argument)
        elif operation == 2:
            answer = kth(tree, root, argument)
        elif operation == 3:
            answer = predecessor(tree, root, argument)
        else:
            answer = successor(tree, root, argument)
        checksum += Int64(index + 1) * (answer + 1025)
    return checksum
