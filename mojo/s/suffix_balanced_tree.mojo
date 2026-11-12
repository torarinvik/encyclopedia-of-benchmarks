from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

comptime SBT_MAX_TEXT = 32
comptime SBT_MAX_INPUT = 33
comptime SBT_LEFT = SBT_MAX_TEXT
comptime SBT_RIGHT = 2 * SBT_MAX_TEXT
comptime SBT_SIZE = 3 * SBT_MAX_TEXT
comptime SBT_TAG = 4 * SBT_MAX_TEXT
comptime SBT_BUFFER = 5 * SBT_MAX_TEXT
comptime SBT_ANSWER = 6 * SBT_MAX_TEXT
comptime SBT_BUFFERED = 7 * SBT_MAX_TEXT
comptime SBT_STATE_SIZE = SBT_BUFFERED + 1
comptime SBT_TAG_LIMIT: Int64 = 1 << 62

fn sbt_node_size(inout state: InlineArray[Int64, SBT_STATE_SIZE], node: Int) -> Int:
    if node < 0: return 0
    return Int(state[SBT_SIZE + node])

fn sbt_suffix_less(inout state: InlineArray[Int64, SBT_STATE_SIZE], x: Int, y: Int, n: Int) -> Bool:
    if state[x] != state[y]: return state[x] < state[y]
    let next_x = state[SBT_TAG + x + 1] if x + 1 < n else 0
    let next_y = state[SBT_TAG + y + 1] if y + 1 < n else 0
    return next_x < next_y

fn sbt_flatten(inout state: InlineArray[Int64, SBT_STATE_SIZE], root: Int):
    if root < 0: return
    sbt_flatten(state, Int(state[SBT_LEFT + root]))
    let buffered = Int(state[SBT_BUFFERED])
    state[SBT_BUFFER + buffered] = Int64(root)
    state[SBT_BUFFERED] = Int64(buffered + 1)
    sbt_flatten(state, Int(state[SBT_RIGHT + root]))

fn sbt_build_balanced(inout state: InlineArray[Int64, SBT_STATE_SIZE], lo: Int, hi: Int,
                      low: Int64, high: Int64) -> Int:
    if lo >= hi: return -1
    let mid = lo + (hi - lo) // 2
    let root = Int(state[SBT_BUFFER + mid])
    let tag = low + (high - low) // 2
    state[SBT_TAG + root] = tag
    let left = sbt_build_balanced(state, lo, mid, low, tag)
    let right = sbt_build_balanced(state, mid + 1, hi, tag, high)
    state[SBT_LEFT + root] = Int64(left)
    state[SBT_RIGHT + root] = Int64(right)
    let left_size = sbt_node_size(state, left)
    let right_size = sbt_node_size(state, right)
    state[SBT_SIZE + root] = Int64(1 + left_size + right_size)
    return root

fn sbt_rebuild(inout state: InlineArray[Int64, SBT_STATE_SIZE], root: Int,
               low: Int64, high: Int64) -> Int:
    state[SBT_BUFFERED] = 0
    sbt_flatten(state, root)
    return sbt_build_balanced(state, 0, Int(state[SBT_BUFFERED]), low, high)

fn sbt_insert(inout state: InlineArray[Int64, SBT_STATE_SIZE], root: Int,
              pos: Int, n: Int, low: Int64, high: Int64) -> Int:
    if root < 0:
        state[SBT_LEFT + pos] = -1
        state[SBT_RIGHT + pos] = -1
        state[SBT_SIZE + pos] = 1
        state[SBT_TAG + pos] = low + (high - low) // 2
        return pos
    let middle = state[SBT_TAG + root]
    if sbt_suffix_less(state, pos, root, n):
        let child = Int(state[SBT_LEFT + root])
        let inserted = sbt_insert(state, child, pos, n, low, middle)
        state[SBT_LEFT + root] = Int64(inserted)
    else:
        let child = Int(state[SBT_RIGHT + root])
        let inserted = sbt_insert(state, child, pos, n, middle, high)
        state[SBT_RIGHT + root] = Int64(inserted)
    let left_child = Int(state[SBT_LEFT + root])
    let right_child = Int(state[SBT_RIGHT + root])
    let left_size = sbt_node_size(state, left_child)
    let right_size = sbt_node_size(state, right_child)
    state[SBT_SIZE + root] = Int64(1 + left_size + right_size)
    if 4 * max(left_size, right_size) >= 3 * Int(state[SBT_SIZE + root]):
        return sbt_rebuild(state, root, low, high)
    return root

fn sbt_inorder(inout state: InlineArray[Int64, SBT_STATE_SIZE], root: Int, inout count: Int):
    if root < 0: return
    sbt_inorder(state, Int(state[SBT_LEFT + root]), count)
    state[SBT_ANSWER + count] = Int64(root)
    count += 1
    sbt_inorder(state, Int(state[SBT_RIGHT + root]), count)

fn sbt_store_le(value: Int64, inout output: InlineArray[UInt8, 8 * SBT_MAX_TEXT], offset: Int):
    let bits = bitcast[UInt64](value)
    for byte in range(8): output[offset + byte] = UInt8((bits >> UInt(8 * byte)) & 255)

@export("suffix_balanced_tree")
fn suffix_balanced_tree(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                        output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > SBT_MAX_INPUT: return -1
    let nv = input[0]
    if nv < 0 or nv > SBT_MAX_TEXT or Int(length) != 1 + Int(nv): return -1
    let n = Int(nv)
    for i in range(n): if input[1 + i] < 0 or input[1 + i] > 255: return -1
    let required = 8 * n
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or Int(capacity) < required: return -2
    var state = InlineArray[Int64, SBT_STATE_SIZE]()
    for i in range(n): state[i] = input[1 + i]
    var root = -1
    for reverse in range(n):
        let pos = n - 1 - reverse
        root = sbt_insert(state, root, pos, n, 0, SBT_TAG_LIMIT)
    var count = 0
    sbt_inorder(state, root, count)
    var staged = InlineArray[UInt8, 8 * SBT_MAX_TEXT]()
    for i in range(count): sbt_store_le(state[SBT_ANSWER + i], staged, 8 * i)
    for i in range(required): output[i] = staged[i]
    return Int64(required)
