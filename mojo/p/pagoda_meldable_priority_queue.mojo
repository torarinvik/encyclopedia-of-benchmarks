from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

comptime MAX_QUEUES = 8
comptime MAX_OPERATIONS = 64
comptime MAX_PARSEABLE_WORDS = 259
comptime NIL: Int64 = -1

struct PagodaState:
    var keys: InlineArray[Int64, MAX_OPERATIONS]
    var leftmost: InlineArray[Int64, MAX_OPERATIONS]
    var rightmost: InlineArray[Int64, MAX_OPERATIONS]
    var roots: InlineArray[Int64, MAX_QUEUES]
    var g_branch: InlineArray[Int64, MAX_OPERATIONS]
    var d_branch: InlineArray[Int64, MAX_OPERATIONS]

    fn __init__(out self):
        self.keys = InlineArray[Int64, MAX_OPERATIONS](fill=0)
        self.leftmost = InlineArray[Int64, MAX_OPERATIONS](fill=NIL)
        self.rightmost = InlineArray[Int64, MAX_OPERATIONS](fill=NIL)
        self.roots = InlineArray[Int64, MAX_QUEUES](fill=NIL)
        self.g_branch = InlineArray[Int64, MAX_OPERATIONS](fill=NIL)
        self.d_branch = InlineArray[Int64, MAX_OPERATIONS](fill=NIL)

fn pg_branch_stack(
    inout state: PagodaState, root: Int64, right_branch: Bool,
    node_count: Int, use_g_stack: Bool
) -> Int:
    var node = state.leftmost[Int(root)]
    if right_branch:
        node = state.rightmost[Int(root)]
    if node < 0 or node >= Int64(node_count):
        return -1
    var count = 0
    while count < node_count:
        if use_g_stack:
            state.g_branch[count] = node
        else:
            state.d_branch[count] = node
        count += 1
        if node == root:
            return count
        if right_branch:
            node = state.rightmost[Int(node)]
        else:
            node = state.leftmost[Int(node)]
        if node < 0 or node >= Int64(node_count):
            return -1
    return -1

fn pg_meld(inout state: PagodaState, g_root: Int64, d_root: Int64, node_count: Int) -> Int64:
    if g_root < 0:
        return d_root
    if d_root < 0:
        return g_root
    let g_count = pg_branch_stack(inout state, g_root, True, node_count, True)
    let d_count = pg_branch_stack(inout state, d_root, False, node_count, False)
    if g_count < 1 or d_count < 1:
        return -2

    var gi = 0
    var di = 0
    var central: Int64 = NIL
    var central_left: Int64 = NIL
    var central_right: Int64 = NIL
    while gi < g_count or di < d_count:
        let take_g = di >= d_count or (
            gi < g_count and state.keys[Int(state.g_branch[gi])] > state.keys[Int(state.d_branch[di])]
        )
        var node: Int64 = NIL
        var kept: Int64 = NIL
        if take_g:
            node = state.g_branch[gi]
            gi += 1
            kept = state.leftmost[Int(node)]
        else:
            node = state.d_branch[di]
            di += 1
            kept = state.rightmost[Int(node)]

        if central >= 0:
            if take_g:
                state.rightmost[Int(central)] = node
                if central_left == central:
                    state.leftmost[Int(central)] = NIL
                else:
                    state.leftmost[Int(central)] = central_left
            else:
                state.leftmost[Int(central)] = node
                if central_right == central:
                    state.rightmost[Int(central)] = NIL
                else:
                    state.rightmost[Int(central)] = central_right

        var new_left: Int64 = NIL
        var new_right: Int64 = NIL
        if take_g:
            if kept >= 0:
                new_left = kept
            else:
                new_left = node
            if central >= 0:
                new_right = central_right
            else:
                new_right = node
        else:
            if central >= 0:
                new_left = central_left
            else:
                new_left = node
            if kept >= 0:
                new_right = kept
            else:
                new_right = node
        state.leftmost[Int(node)] = new_left
        state.rightmost[Int(node)] = new_right
        central = node
        central_left = new_left
        central_right = new_right
    return central

fn pg_extract_min(inout state: PagodaState, root: Int64, node_count: Int) -> Int64:
    let old_left = state.leftmost[Int(root)]
    let old_right = state.rightmost[Int(root)]
    var left_child: Int64 = NIL
    var right_child: Int64 = NIL
    if old_left != root:
        var node = old_left
        var steps = 0
        while node >= 0 and node < Int64(node_count) and state.leftmost[Int(node)] != root and steps < node_count:
            node = state.leftmost[Int(node)]
            steps += 1
        if node < 0 or node >= Int64(node_count) or state.leftmost[Int(node)] != root:
            return -2
        left_child = node
    if old_right != root:
        var node = old_right
        var steps = 0
        while node >= 0 and node < Int64(node_count) and state.rightmost[Int(node)] != root and steps < node_count:
            node = state.rightmost[Int(node)]
            steps += 1
        if node < 0 or node >= Int64(node_count) or state.rightmost[Int(node)] != root:
            return -2
        right_child = node

    if left_child >= 0:
        state.leftmost[Int(left_child)] = old_left
        if state.rightmost[Int(left_child)] < 0:
            state.rightmost[Int(left_child)] = left_child
    if right_child >= 0:
        state.rightmost[Int(right_child)] = old_right
        if state.leftmost[Int(right_child)] < 0:
            state.leftmost[Int(right_child)] = right_child
    let new_root = pg_meld(inout state, right_child, left_child, node_count)
    state.leftmost[Int(root)] = NIL
    state.rightmost[Int(root)] = NIL
    return new_root

@export("pagoda_meldable_priority_queue")
fn pagoda_meldable_priority_queue(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > MAX_PARSEABLE_WORDS:
        return -1
    let queue_count = input[0]
    let operation_count = input[1]
    if queue_count < 1 or queue_count > MAX_QUEUES or operation_count < 0 or
       operation_count > MAX_OPERATIONS or length != c_size_t(2 + 4 * operation_count) or length > 258:
        return -1

    var state = PagodaState()
    var node_count = 0
    var result: Int64 = 0
    for op in range(Int(operation_count)):
        let offset = 2 + 4 * op
        let opcode = input[offset]
        let first = input[offset + 1]
        let second = input[offset + 2]
        let priority = input[offset + 3]
        if opcode == 1:
            if first < 0 or first >= queue_count or second != 0 or priority < -1000 or
               priority > 1000 or node_count >= MAX_OPERATIONS:
                return -1
            for i in range(node_count):
                if state.keys[i] == priority:
                    return -1
            let node = node_count
            node_count += 1
            state.keys[node] = priority
            state.leftmost[node] = Int64(node)
            state.rightmost[node] = Int64(node)
            let current_root = state.roots[Int(first)]
            let merged = pg_meld(inout state, current_root, Int64(node), node_count)
            if merged < 0:
                return -1
            state.roots[Int(first)] = merged
        elif opcode == 2:
            if first < 0 or first >= queue_count or second < 0 or second >= queue_count or
               first == second or priority != 0:
                return -1
            let destination_root = state.roots[Int(first)]
            let source_root = state.roots[Int(second)]
            let merged = pg_meld(inout state, destination_root, source_root, node_count)
            if merged == -2:
                return -1
            state.roots[Int(first)] = merged
            state.roots[Int(second)] = NIL
        elif opcode == 3 or opcode == 4:
            if first < 0 or first >= queue_count or second != 0 or priority != 0 or state.roots[Int(first)] < 0:
                return -1
            let root = state.roots[Int(first)]
            result += (Int64(op) + 1) * (state.keys[Int(root)] + 1001)
            if opcode == 4:
                let new_root = pg_extract_min(inout state, root, node_count)
                if new_root == -2:
                    return -1
                state.roots[Int(first)] = new_root
        else:
            return -1
    return result
