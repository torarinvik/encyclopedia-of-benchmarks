from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

comptime MAX_Q = 32
comptime ARENA = 64
comptime MIN_KEY: Int64 = -15
comptime MAX_KEY: Int64 = 15

struct DietNode:
    var lo: Int64
    var hi: Int64
    var left: Int
    var right: Int

    fn __init__(out self, lo: Int64, hi: Int64, left: Int, right: Int):
        self.lo = lo
        self.hi = hi
        self.left = left
        self.right = right

struct DietState:
    var nodes: InlineArray[DietNode, ARENA]
    var used: Int
    var interval_count: Int

    fn __init__(out self):
        self.nodes = InlineArray[DietNode, ARENA](fill=DietNode(0, 0, -1, -1))
        self.used = 0
        self.interval_count = 0

fn diet_new(inout state: DietState, lo: Int64, hi: Int64,
            left: Int, right: Int) -> Int:
    let index = state.used
    state.nodes[index] = DietNode(lo, hi, left, right)
    state.used += 1
    return index

fn diet_max_interval(inout state: DietState, root_input: Int) -> (Int64, Int64):
    var root = root_input
    while state.nodes[root].right >= 0:
        root = state.nodes[root].right
    return (state.nodes[root].lo, state.nodes[root].hi)

fn diet_min_interval(inout state: DietState, root_input: Int) -> (Int64, Int64):
    var root = root_input
    while state.nodes[root].left >= 0:
        root = state.nodes[root].left
    return (state.nodes[root].lo, state.nodes[root].hi)

fn diet_pop_max(inout state: DietState, root: Int,
                inout lo: Int64, inout hi: Int64) -> Int:
    if state.nodes[root].right < 0:
        lo = state.nodes[root].lo
        hi = state.nodes[root].hi
        return state.nodes[root].left
    state.nodes[root].right = diet_pop_max(
        inout state, state.nodes[root].right, inout lo, inout hi
    )
    return root

fn diet_pop_min(inout state: DietState, root: Int,
                inout lo: Int64, inout hi: Int64) -> Int:
    if state.nodes[root].left < 0:
        lo = state.nodes[root].lo
        hi = state.nodes[root].hi
        return state.nodes[root].right
    state.nodes[root].left = diet_pop_min(
        inout state, state.nodes[root].left, inout lo, inout hi
    )
    return root

fn diet_insert(inout state: DietState, root: Int, key: Int64,
               inout changed: Bool) -> Int:
    if root < 0:
        state.interval_count += 1
        changed = True
        return diet_new(inout state, key, key, -1, -1)
    if key < state.nodes[root].lo:
        if key + 1 == state.nodes[root].lo:
            state.nodes[root].lo = key
            changed = True
            if state.nodes[root].left >= 0:
                let (pred_lo, pred_hi) = diet_max_interval(inout state, state.nodes[root].left)
                if pred_hi + 1 == key:
                    var lo: Int64 = 0
                    var hi: Int64 = 0
                    state.nodes[root].left = diet_pop_max(
                        inout state, state.nodes[root].left, inout lo, inout hi
                    )
                    state.nodes[root].lo = lo
                    state.interval_count -= 1
        else:
            state.nodes[root].left = diet_insert(
                inout state, state.nodes[root].left, key, inout changed
            )
        return root
    if key > state.nodes[root].hi:
        if key == state.nodes[root].hi + 1:
            state.nodes[root].hi = key
            changed = True
            if state.nodes[root].right >= 0:
                let (succ_lo, _) = diet_min_interval(inout state, state.nodes[root].right)
                if key + 1 == succ_lo:
                    var lo: Int64 = 0
                    var hi: Int64 = 0
                    state.nodes[root].right = diet_pop_min(
                        inout state, state.nodes[root].right, inout lo, inout hi
                    )
                    state.nodes[root].hi = hi
                    state.interval_count -= 1
        else:
            state.nodes[root].right = diet_insert(
                inout state, state.nodes[root].right, key, inout changed
            )
        return root
    changed = False
    return root

fn diet_delete(inout state: DietState, root: Int, key: Int64,
               inout changed: Bool) -> Int:
    if root < 0:
        changed = False
        return root
    if key < state.nodes[root].lo:
        state.nodes[root].left = diet_delete(
            inout state, state.nodes[root].left, key, inout changed
        )
        return root
    if key > state.nodes[root].hi:
        state.nodes[root].right = diet_delete(
            inout state, state.nodes[root].right, key, inout changed
        )
        return root
    changed = True
    if state.nodes[root].lo == state.nodes[root].hi:
        state.interval_count -= 1
        if state.nodes[root].left < 0: return state.nodes[root].right
        if state.nodes[root].right < 0: return state.nodes[root].left
        var lo: Int64 = 0
        var hi: Int64 = 0
        state.nodes[root].left = diet_pop_max(
            inout state, state.nodes[root].left, inout lo, inout hi
        )
        state.nodes[root].lo = lo
        state.nodes[root].hi = hi
        return root
    if key == state.nodes[root].lo:
        state.nodes[root].lo += 1
        return root
    if key == state.nodes[root].hi:
        state.nodes[root].hi -= 1
        return root
    let piece = diet_new(inout state, key + 1, state.nodes[root].hi, -1, state.nodes[root].right)
    state.nodes[root].hi = key - 1
    state.nodes[root].right = piece
    state.interval_count += 1
    return root

fn diet_contains(inout state: DietState, root_input: Int, key: Int64) -> Bool:
    var root = root_input
    while root >= 0:
        if key < state.nodes[root].lo:
            root = state.nodes[root].left
        elif key > state.nodes[root].hi:
            root = state.nodes[root].right
        else:
            return True
    return False

@export("discrete_interval_encoding_tree")
fn discrete_interval_encoding_tree(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > 2 + 2 * MAX_Q:
        return -1
    let q_value = input[0]
    if q_value < 0 or q_value > MAX_Q: return -1
    let q = Int(q_value)
    if length != c_size_t(1 + 2 * q): return -1
    for op in range(q):
        let opcode = input[1 + 2 * op]
        let key = input[2 + 2 * op]
        if opcode < 0 or opcode > 2 or key < MIN_KEY or key > MAX_KEY: return -1
    let required = 8 * q
    if (required > 0 and output == UnsafePointer[UInt8, MutAnyOrigin]()) or capacity < c_size_t(required):
        return -2

    var state = DietState()
    var root = -1
    var cardinality = 0
    var staged = InlineArray[Int64, MAX_Q](fill=0)
    for op in range(q):
        let opcode = Int(input[1 + 2 * op])
        let key = input[2 + 2 * op]
        var changed = False
        if opcode == 0:
            root = diet_insert(inout state, root, key, inout changed)
            if changed: cardinality += 1
        elif opcode == 1:
            root = diet_delete(inout state, root, key, inout changed)
            if changed: cardinality -= 1
        let present = if diet_contains(inout state, root, key): 1 else: 0
        staged[op] = 64 * Int64(cardinality) + 2 * Int64(state.interval_count) + Int64(present)
    for op in range(q):
        let word = UInt64(staged[op])
        for byte in range(8):
            output[8 * op + byte] = UInt8((word >> (8 * byte)) & 0xFF)
    return Int64(required)
