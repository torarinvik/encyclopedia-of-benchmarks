from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

comptime MAX_TEXT_LENGTH = 32
comptime MAX_INPUT_LENGTH = 34
comptime MAX_NODES = 64

struct BlindTrie:
    var is_leaf: InlineArray[Int32, MAX_NODES]
    var split_pos: InlineArray[Int32, MAX_NODES]
    var leaf_start: InlineArray[Int32, MAX_NODES]
    var edge_symbol: InlineArray[Int32, MAX_NODES]
    var first_child: InlineArray[Int32, MAX_NODES]
    var next_sibling: InlineArray[Int32, MAX_NODES]
    var count: Int32
    var root: Int32

    fn __init__(out self):
        self.is_leaf = InlineArray[Int32, MAX_NODES](fill=0)
        self.split_pos = InlineArray[Int32, MAX_NODES](fill=0)
        self.leaf_start = InlineArray[Int32, MAX_NODES](fill=-1)
        self.edge_symbol = InlineArray[Int32, MAX_NODES](fill=0)
        self.first_child = InlineArray[Int32, MAX_NODES](fill=-1)
        self.next_sibling = InlineArray[Int32, MAX_NODES](fill=-1)
        self.count = 0
        self.root = -1

fn symbol_at(input: UnsafePointer[Int64, ImmutAnyOrigin], n: Int,
             start: Int, depth: Int) -> Int:
    let position = start + depth
    if position >= n: return 0
    return Int(input[position + 1]) + 1

fn common_prefix(input: UnsafePointer[Int64, ImmutAnyOrigin], n: Int,
                 left: Int, right: Int) -> Int:
    var depth = 0
    while symbol_at(input, n, left, depth) == symbol_at(input, n, right, depth):
        depth += 1
    return depth

fn new_node(inout trie: BlindTrie, is_leaf: Bool, value: Int) -> Int:
    let index = Int(trie.count)
    trie.count += 1
    trie.is_leaf[index] = Int32(1 if is_leaf else 0)
    trie.split_pos[index] = Int32(0 if is_leaf else value)
    trie.leaf_start[index] = Int32(value if is_leaf else -1)
    trie.first_child[index] = -1
    trie.next_sibling[index] = -1
    return index

fn find_child(inout trie: BlindTrie, parent: Int, symbol: Int) -> Int:
    var child = Int(trie.first_child[parent])
    while child >= 0:
        if Int(trie.edge_symbol[child]) == symbol: return child
        if Int(trie.edge_symbol[child]) > symbol: return -1
        child = Int(trie.next_sibling[child])
    return -1

fn link_child(inout trie: BlindTrie, parent: Int, child: Int):
    let symbol = trie.edge_symbol[child]
    var previous = -1
    var cursor = Int(trie.first_child[parent])
    while cursor >= 0 and trie.edge_symbol[cursor] < symbol:
        previous = cursor
        cursor = Int(trie.next_sibling[cursor])
    trie.next_sibling[child] = Int32(cursor)
    if previous < 0:
        trie.first_child[parent] = Int32(child)
    else:
        trie.next_sibling[previous] = Int32(child)

fn replace_child(inout trie: BlindTrie, parent: Int, old_child: Int, new_child: Int):
    var previous = -1
    var cursor = Int(trie.first_child[parent])
    while cursor != old_child:
        previous = cursor
        cursor = Int(trie.next_sibling[cursor])
    trie.edge_symbol[new_child] = trie.edge_symbol[old_child]
    trie.next_sibling[new_child] = trie.next_sibling[old_child]
    if previous < 0:
        trie.first_child[parent] = Int32(new_child)
    else:
        trie.next_sibling[previous] = Int32(new_child)

fn insert_suffix(inout trie: BlindTrie, input: UnsafePointer[Int64, ImmutAnyOrigin],
                 n: Int, start: Int):
    let fresh = new_node(trie, True, start)
    if trie.is_leaf[Int(trie.root)] != 0:
        let old = Int(trie.root)
        let depth = common_prefix(input, n, Int(trie.leaf_start[old]), start)
        let middle = new_node(trie, False, depth)
        trie.edge_symbol[old] = Int32(symbol_at(input, n, Int(trie.leaf_start[old]), depth))
        trie.edge_symbol[fresh] = Int32(symbol_at(input, n, start, depth))
        link_child(trie, middle, old)
        link_child(trie, middle, fresh)
        trie.root = Int32(middle)
        return

    var leaf = Int(trie.root)
    while trie.is_leaf[leaf] == 0:
        let symbol = symbol_at(input, n, start, Int(trie.split_pos[leaf]))
        var child = find_child(trie, leaf, symbol)
        if child < 0: child = Int(trie.first_child[leaf])
        leaf = child
    let old_start = Int(trie.leaf_start[leaf])
    let depth = common_prefix(input, n, start, old_start)
    var parent = -1
    var current = Int(trie.root)
    while trie.is_leaf[current] == 0 and Int(trie.split_pos[current]) < depth:
        let symbol = symbol_at(input, n, start, Int(trie.split_pos[current]))
        var child = find_child(trie, current, symbol)
        if child < 0: child = Int(trie.first_child[current])
        parent = current
        current = child
    if trie.is_leaf[current] == 0 and Int(trie.split_pos[current]) == depth:
        trie.edge_symbol[fresh] = Int32(symbol_at(input, n, start, depth))
        link_child(trie, current, fresh)
        return

    let middle = new_node(trie, False, depth)
    if parent < 0:
        trie.root = Int32(middle)
    else:
        replace_child(trie, parent, current, middle)
    trie.edge_symbol[current] = Int32(symbol_at(input, n, old_start, depth))
    trie.edge_symbol[fresh] = Int32(symbol_at(input, n, start, depth))
    link_child(trie, middle, current)
    link_child(trie, middle, fresh)

fn ordered_leaves(inout trie: BlindTrie,
                  inout output: InlineArray[Int32, MAX_TEXT_LENGTH]) -> Int:
    var stack = InlineArray[Int32, MAX_NODES](fill=0)
    var top = 1
    var count = 0
    stack[0] = trie.root
    while top > 0:
        top -= 1
        let node = Int(stack[top])
        if trie.is_leaf[node] != 0:
            output[count] = trie.leaf_start[node]
            count += 1
            continue
        var children = InlineArray[Int32, MAX_TEXT_LENGTH](fill=0)
        var child_count = 0
        var child = Int(trie.first_child[node])
        while child >= 0:
            children[child_count] = Int32(child)
            child_count += 1
            child = Int(trie.next_sibling[child])
        while child_count > 0:
            child_count -= 1
            stack[top] = children[child_count]
            top += 1
    return count

fn store_i64_le(output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int, value: Int):
    let bits = UInt64(value)
    for byte in range(8): output[offset + byte] = UInt8((bits >> (byte * 8)) & 255)

@export("suffix_array_blind_trie")
fn suffix_array_blind_trie(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t,
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > c_size_t(MAX_INPUT_LENGTH):
        return -1
    let count_value = input[0]
    if count_value < 0 or count_value > MAX_TEXT_LENGTH: return -1
    let count = Int(count_value)
    if length != c_size_t(count + 1): return -1
    for index in range(count):
        if input[index + 1] < 0 or input[index + 1] > 255: return -1
    let output_bytes = count * 8
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(output_bytes): return -2
    if count == 0: return 0

    var trie = BlindTrie()
    trie.root = Int32(new_node(trie, True, 0))
    for start in range(1, count): insert_suffix(trie, input, count, start)
    var order = InlineArray[Int32, MAX_TEXT_LENGTH](fill=0)
    let order_count = ordered_leaves(trie, order)
    for index in range(order_count): store_i64_le(output, index * 8, Int(order[index]))
    return Int64(output_bytes)
