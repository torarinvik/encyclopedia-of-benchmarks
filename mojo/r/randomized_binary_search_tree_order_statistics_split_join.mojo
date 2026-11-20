from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

fn rbst_size(inout sizes: InlineArray[Int32, 65], root: Int32) -> Int32:
    if root < 0: return 0
    sizes[Int(root)]

fn rbst_refresh(inout sizes: InlineArray[Int32, 65], inout lefts: InlineArray[Int32, 65], inout rights: InlineArray[Int32, 65], root: Int32):
    sizes[Int(root)] = 1 + rbst_size(sizes, lefts[Int(root)]) + rbst_size(sizes, rights[Int(root)])

fn rbst_randbelow(inout random_state: UInt32, bound: UInt32) -> UInt32:
    let threshold = UInt64((UInt64(1) << 32) % UInt64(bound))
    while True:
        random_state = UInt32((UInt64(random_state) * 1664525 + 1013904223) & 0xffffffff)
        let raw = random_state
        if UInt64(raw) >= threshold: return raw % bound
    0

fn rbst_make_node(inout keys: InlineArray[Int64, 65], inout sizes: InlineArray[Int32, 65], inout lefts: InlineArray[Int32, 65], inout rights: InlineArray[Int32, 65], inout used: Int32, key: Int64, left: Int32, right: Int32) -> Int32:
    used += 1
    let node = used
    keys[Int(node)] = key
    lefts[Int(node)] = left
    rights[Int(node)] = right
    rbst_refresh(sizes, lefts, rights, node)
    node

fn rbst_split(inout keys: InlineArray[Int64, 65], inout sizes: InlineArray[Int32, 65], inout lefts: InlineArray[Int32, 65], inout rights: InlineArray[Int32, 65], root: Int32, pivot: Int64) -> (Int32, Int32):
    if root < 0: return (-1, -1)
    let index = Int(root)
    if keys[index] < pivot:
        let result = rbst_split(keys, sizes, lefts, rights, rights[index], pivot)
        rights[index] = result.0
        rbst_refresh(sizes, lefts, rights, root)
        return (root, result.1)
    let result = rbst_split(keys, sizes, lefts, rights, lefts[index], pivot)
    lefts[index] = result.1
    rbst_refresh(sizes, lefts, rights, root)
    (result.0, root)

fn rbst_join(inout sizes: InlineArray[Int32, 65], inout lefts: InlineArray[Int32, 65], inout rights: InlineArray[Int32, 65], inout random_state: UInt32, left: Int32, right: Int32) -> Int32:
    if left < 0: return right
    if right < 0: return left
    let left_size = UInt32(rbst_size(sizes, left))
    let total = left_size + UInt32(rbst_size(sizes, right))
    if rbst_randbelow(random_state, total) < left_size:
        let child = rights[Int(left)]
        rights[Int(left)] = rbst_join(sizes, lefts, rights, random_state, child, right)
        rbst_refresh(sizes, lefts, rights, left)
        return left
    let child = lefts[Int(right)]
    lefts[Int(right)] = rbst_join(sizes, lefts, rights, random_state, left, child)
    rbst_refresh(sizes, lefts, rights, right)
    right

fn rbst_contains(inout keys: InlineArray[Int64, 65], inout lefts: InlineArray[Int32, 65], inout rights: InlineArray[Int32, 65], root_start: Int32, key: Int64) -> Bool:
    var root = root_start
    while root >= 0:
        let index = Int(root)
        if key == keys[index]: return True
        if key < keys[index]: root = lefts[index]
        else: root = rights[index]
    False

fn rbst_insert(inout keys: InlineArray[Int64, 65], inout sizes: InlineArray[Int32, 65], inout lefts: InlineArray[Int32, 65], inout rights: InlineArray[Int32, 65], inout used: Int32, inout random_state: UInt32, root: Int32, key: Int64) -> Int32:
    if root < 0: return rbst_make_node(keys, sizes, lefts, rights, used, key, -1, -1)
    if rbst_randbelow(random_state, UInt32(rbst_size(sizes, root) + 1)) == 0:
        let parts = rbst_split(keys, sizes, lefts, rights, root, key)
        return rbst_make_node(keys, sizes, lefts, rights, used, key, parts.0, parts.1)
    let index = Int(root)
    if key < keys[index]:
        let child = lefts[index]
        lefts[index] = rbst_insert(keys, sizes, lefts, rights, used, random_state, child, key)
    else:
        let child = rights[index]
        rights[index] = rbst_insert(keys, sizes, lefts, rights, used, random_state, child, key)
    rbst_refresh(sizes, lefts, rights, root)
    root

fn rbst_erase(inout keys: InlineArray[Int64, 65], inout sizes: InlineArray[Int32, 65], inout lefts: InlineArray[Int32, 65], inout rights: InlineArray[Int32, 65], inout random_state: UInt32, root: Int32, key: Int64) -> Int32:
    if root < 0: return -1
    let index = Int(root)
    if key == keys[index]: return rbst_join(sizes, lefts, rights, random_state, lefts[index], rights[index])
    if key < keys[index]:
        let child = lefts[index]
        lefts[index] = rbst_erase(keys, sizes, lefts, rights, random_state, child, key)
    else:
        let child = rights[index]
        rights[index] = rbst_erase(keys, sizes, lefts, rights, random_state, child, key)
    rbst_refresh(sizes, lefts, rights, root)
    root

fn rbst_kth(inout keys: InlineArray[Int64, 65], inout sizes: InlineArray[Int32, 65], inout lefts: InlineArray[Int32, 65], inout rights: InlineArray[Int32, 65], root_start: Int32, rank_start: Int32) -> Int64:
    if rank_start > rbst_size(sizes, root_start): return -1
    var root = root_start
    var rank = rank_start
    while root >= 0:
        let index = Int(root)
        let left_size = rbst_size(sizes, lefts[index])
        if rank == left_size + 1: return keys[index]
        if rank <= left_size: root = lefts[index]
        else:
            rank -= left_size + 1
            root = rights[index]
    -1

fn rbst_minmax(inout keys: InlineArray[Int64, 65], inout links: InlineArray[Int32, 65], root_start: Int32) -> Int64:
    if root_start < 0: return -1
    var root = root_start
    while True:
        let link = links[Int(root)]
        if link < 0: return keys[Int(root)]
        root = link

fn rbst_valid_operation(input: view[Int64], offset: Int) -> Bool:
    let op = input[offset]
    let a = input[offset + 1]
    let b = input[offset + 2]
    let c = input[offset + 3]
    if op == 0 or op == 1: return (a == 0 or a == 1) and b >= 0 and b <= 1000 and c == 0
    if op == 2: return (a == 0 or a == 1) and b >= 1 and b <= 65 and c == 0
    if op == 3: return (a == 0 or a == 1) and (b == 0 or b == 1) and a != b and c >= 0 and c <= 1001
    if op == 4: return (a == 0 or a == 1) and (b == 0 or b == 1) and a != b and c == 0
    False

fn rbst_impl(input: view[Int64]) -> Int64:
    if input.len() < 3 or input.len() > 164: return -1
    let n_value = input[0]
    let q_value = input[1]
    let seed_value = input[2]
    if n_value < 0 or n_value > 32 or q_value < 0 or q_value > 32 or seed_value < 0 or seed_value > 4294967295: return -1
    let n = Int(n_value)
    let q = Int(q_value)
    if input.len() != 3 + n + 4 * q: return -1
    for i in range(n):
        if input[3 + i] < 0 or input[3 + i] > 1000 or (i > 0 and input[2 + i] >= input[3 + i]): return -1
    let start = 3 + n
    for op in range(q):
        if not rbst_valid_operation(input, start + 4 * op): return -1

    var keys = InlineArray[Int64, 65]()
    var sizes = InlineArray[Int32, 65]()
    var lefts = InlineArray[Int32, 65](fill=-1)
    var rights = InlineArray[Int32, 65](fill=-1)
    var used: Int32 = 0
    var random_state = UInt32(seed_value)
    var roots = InlineArray[Int32, 2](fill=-1)
    for i in range(n):
        roots[0] = rbst_insert(keys, sizes, lefts, rights, used, random_state, roots[0], input[3 + i])
    var checksum: Int64 = 0
    var query_number: Int64 = 0
    for op in range(q):
        let offset = start + 4 * op
        let code = input[offset]
        let tree = Int32(input[offset + 1])
        let arg = input[offset + 2]
        let extra = input[offset + 3]
        if code == 0:
            if not rbst_contains(keys, lefts, rights, roots[Int(tree)], arg):
                roots[Int(tree)] = rbst_insert(keys, sizes, lefts, rights, used, random_state, roots[Int(tree)], arg)
        elif code == 1:
            roots[Int(tree)] = rbst_erase(keys, sizes, lefts, rights, random_state, roots[Int(tree)], arg)
        elif code == 2:
            query_number += 1
            checksum += query_number * (rbst_kth(keys, sizes, lefts, rights, roots[Int(tree)], Int32(arg)) + 1)
        elif code == 3:
            let destination = Int32(arg)
            if roots[Int(destination)] >= 0: return -1
            let parts = rbst_split(keys, sizes, lefts, rights, roots[Int(tree)], extra)
            roots[Int(tree)] = parts.0
            roots[Int(destination)] = parts.1
        else:
            let right_tree = Int32(arg)
            let left_max = rbst_minmax(keys, rights, roots[Int(tree)])
            let right_min = rbst_minmax(keys, lefts, roots[Int(right_tree)])
            if left_max >= 0 and right_min >= 0 and left_max >= right_min: return -1
            roots[Int(tree)] = rbst_join(sizes, lefts, rights, random_state, roots[Int(tree)], roots[Int(right_tree)])
            roots[Int(right_tree)] = -1
    checksum

@export("randomized_binary_search_tree_order_statistics_split_join")
fn randomized_binary_search_tree_order_statistics_split_join(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3 or length > 164: return -1
    var values = InlineArray[Int64, 164]()
    for index in range(Int(length)):
        values[index] = input[index]
    rbst_impl(values[0:Int(length)])
