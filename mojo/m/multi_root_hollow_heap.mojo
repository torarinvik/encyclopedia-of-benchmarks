from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

comptime MAX_OPERATIONS = 64
comptime MAX_ITEMS = 32
comptime MAX_NODES = 64
comptime MAX_INPUT_LENGTH = 194

struct MultiRootHollowState:
    var keys: InlineArray[Int64, MAX_NODES]
    var items: InlineArray[Int, MAX_NODES]
    var ranks: InlineArray[Int, MAX_NODES]
    var parents: InlineArray[Int, MAX_NODES]
    var alive: InlineArray[Bool, MAX_NODES]
    var item_nodes: InlineArray[Int, MAX_ITEMS]
    var active: InlineArray[Bool, MAX_ITEMS]
    var node_count: Int

    fn __init__(out self):
        self.keys = InlineArray[Int64, MAX_NODES](fill=0)
        self.items = InlineArray[Int, MAX_NODES](fill=0)
        self.ranks = InlineArray[Int, MAX_NODES](fill=0)
        self.parents = InlineArray[Int, MAX_NODES](fill=-2)
        self.alive = InlineArray[Bool, MAX_NODES](fill=False)
        self.item_nodes = InlineArray[Int, MAX_ITEMS](fill=-1)
        self.active = InlineArray[Bool, MAX_ITEMS](fill=False)
        self.node_count = 0

fn mrhh_minimum_root(state: MultiRootHollowState) -> Int:
    var best = -1
    for node in range(state.node_count):
        if not state.alive[node] or state.parents[node] != -1 or state.items[node] < 0:
            continue
        if best < 0:
            best = node
        elif state.keys[node] < state.keys[best] or (state.keys[node] == state.keys[best] and (state.items[node] < state.items[best] or (state.items[node] == state.items[best] and node < best))):
            best = node
    return best

fn mrhh_cleanup(inout state: MultiRootHollowState):
    while True:
        var hollow_root = -1
        for node in range(state.node_count):
            if state.alive[node] and state.parents[node] == -1 and state.items[node] == -1:
                hollow_root = node
                break
        if hollow_root < 0:
            break
        for child in range(state.node_count):
            if state.alive[child] and state.parents[child] == hollow_root:
                state.parents[child] = -1
        state.alive[hollow_root] = False
        state.parents[hollow_root] = -2

    while True:
        var duplicate_rank = -1
        for rank_value in range(state.node_count):
            var roots_at_rank = 0
            for node in range(state.node_count):
                if state.alive[node] and state.parents[node] == -1 and state.items[node] >= 0 and state.ranks[node] == rank_value:
                    roots_at_rank += 1
            if roots_at_rank >= 2:
                duplicate_rank = rank_value
                break
        if duplicate_rank < 0:
            return

        var first = -1
        var second = -1
        for node in range(state.node_count):
            if state.alive[node] and state.parents[node] == -1 and state.items[node] >= 0 and state.ranks[node] == duplicate_rank:
                if first < 0:
                    first = node
                elif second < 0:
                    second = node
                    break
        var winner = first
        var loser = second
        if state.keys[second] < state.keys[first] or (state.keys[second] == state.keys[first] and (state.items[second] < state.items[first] or (state.items[second] == state.items[first] and second < first))):
            winner = second
            loser = first
        state.parents[loser] = winner
        state.ranks[winner] += 1

@export("multi_root_hollow_heap")
fn multi_root_hollow_heap(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > c_size_t(MAX_INPUT_LENGTH):
        return -1
    let operation_value = input[0]
    if operation_value < 0 or operation_value > MAX_OPERATIONS:
        return -1
    let operation_count = Int(operation_value)
    if length != c_size_t(1 + 3 * operation_count) or length > 193:
        return -1

    var state = MultiRootHollowState()
    var result: Int64 = 0
    for operation_index in range(operation_count):
        let offset = 1 + 3 * operation_index
        let opcode = input[offset]
        let item_value = input[offset + 1]
        let value = input[offset + 2]
        if opcode == 1:
            if item_value < 0 or item_value >= MAX_ITEMS or value < 0 or value > 1_000_000:
                return -1
            let item_id = Int(item_value)
            if state.active[item_id] or state.node_count >= MAX_NODES:
                return -1
            let node = state.node_count
            state.node_count += 1
            state.keys[node] = value
            state.items[node] = item_id
            state.ranks[node] = 0
            state.parents[node] = -1
            state.alive[node] = True
            state.item_nodes[item_id] = node
            state.active[item_id] = True
        elif opcode == 2:
            if item_value < 0 or item_value >= MAX_ITEMS or value < 0 or value > 1_000_000:
                return -1
            let item_id = Int(item_value)
            if not state.active[item_id] or state.node_count >= MAX_NODES:
                return -1
            let old_node = state.item_nodes[item_id]
            if value >= state.keys[old_node]:
                return -1
            let old_rank = state.ranks[old_node]
            let new_rank = old_rank - 2 if old_rank > 2 else 0
            let new_node = state.node_count
            state.node_count += 1
            state.items[old_node] = -1
            state.keys[new_node] = value
            state.items[new_node] = item_id
            state.ranks[new_node] = new_rank
            state.parents[new_node] = -1
            state.alive[new_node] = True
            for child in range(new_node):
                if state.alive[child] and state.parents[child] == old_node and state.ranks[child] < new_rank:
                    state.parents[child] = new_node
            state.item_nodes[item_id] = new_node
        elif opcode == 3:
            if item_value != 0 or value != 0:
                return -1
            let root = mrhh_minimum_root(state)
            if root < 0:
                return -1
            let item_id = state.items[root]
            state.active[item_id] = False
            state.item_nodes[item_id] = -1
            state.items[root] = -1
            result += Int64(operation_index + 1) * (state.keys[root] + 1) + Int64(item_id)
            mrhh_cleanup(state)
        elif opcode == 4:
            if item_value != 0 or value != 0:
                return -1
            let root = mrhh_minimum_root(state)
            if root < 0:
                return -1
            result += Int64(operation_index + 1) * (state.keys[root] + 1) + Int64(state.items[root])
        elif opcode == 5:
            if item_value < 0 or item_value >= MAX_ITEMS or value != 0:
                return -1
            let item_id = Int(item_value)
            if not state.active[item_id]:
                return -1
            let node = state.item_nodes[item_id]
            let was_minimum = node == mrhh_minimum_root(state)
            state.active[item_id] = False
            state.item_nodes[item_id] = -1
            state.items[node] = -1
            if was_minimum:
                mrhh_cleanup(state)
        else:
            return -1
    return result
