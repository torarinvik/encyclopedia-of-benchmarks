from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

comptime MAX_OPERATIONS = 64
comptime MAX_ITEMS = 32
comptime MAX_NODES = 64
comptime MAX_INPUT_LENGTH = 194

struct RankPairingState:
    var keys: InlineArray[Int64, MAX_NODES]
    var items: InlineArray[Int, MAX_NODES]
    var ranks: InlineArray[Int, MAX_NODES]
    var left: InlineArray[Int, MAX_NODES]
    var right: InlineArray[Int, MAX_NODES]
    var parents: InlineArray[Int, MAX_NODES]
    var alive: InlineArray[Bool, MAX_NODES]
    var item_nodes: InlineArray[Int, MAX_ITEMS]
    var active: InlineArray[Bool, MAX_ITEMS]
    var node_count: Int

    fn __init__(out self):
        self.keys = InlineArray[Int64, MAX_NODES](fill=0)
        self.items = InlineArray[Int, MAX_NODES](fill=-1)
        self.ranks = InlineArray[Int, MAX_NODES](fill=0)
        self.left = InlineArray[Int, MAX_NODES](fill=-1)
        self.right = InlineArray[Int, MAX_NODES](fill=-1)
        self.parents = InlineArray[Int, MAX_NODES](fill=-2)
        self.alive = InlineArray[Bool, MAX_NODES](fill=False)
        self.item_nodes = InlineArray[Int, MAX_ITEMS](fill=-1)
        self.active = InlineArray[Bool, MAX_ITEMS](fill=False)
        self.node_count = 0

fn rph_rank(ranks: InlineArray[Int, MAX_NODES], node: Int) -> Int:
    if node < 0:
        return -1
    return ranks[node]

fn rph_minimum_root(state: RankPairingState) -> Int:
    var best = -1
    for node in range(state.node_count):
        if not state.alive[node] or state.parents[node] != -1:
            continue
        if best < 0:
            best = node
        elif state.keys[node] < state.keys[best] or (state.keys[node] == state.keys[best] and (state.items[node] < state.items[best] or (state.items[node] == state.items[best] and node < best))):
            best = node
    return best

fn rph_consolidate(inout state: RankPairingState):
    while True:
        var duplicate_rank = -1
        for rank_value in range(state.node_count):
            var roots_at_rank = 0
            for node in range(state.node_count):
                if state.alive[node] and state.parents[node] == -1 and state.ranks[node] == rank_value:
                    roots_at_rank += 1
            if roots_at_rank >= 2:
                duplicate_rank = rank_value
                break
        if duplicate_rank < 0:
            return

        var first = -1
        var second = -1
        for node in range(state.node_count):
            if state.alive[node] and state.parents[node] == -1 and state.ranks[node] == duplicate_rank:
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
        let old_left = state.left[winner]
        state.left[winner] = loser
        state.parents[loser] = winner
        state.right[loser] = old_left
        if old_left >= 0:
            state.parents[old_left] = loser
        state.ranks[winner] += 1

@export("rank_pairing_heap")
fn rank_pairing_heap(
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

    var state = RankPairingState()
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
            state.left[node] = -1
            state.right[node] = -1
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
            let node = state.item_nodes[item_id]
            if value >= state.keys[node]:
                return -1
            state.keys[node] = value
            if state.parents[node] >= 0:
                let old_parent = state.parents[node]
                let next_sibling = state.right[node]
                if state.left[old_parent] == node:
                    state.left[old_parent] = next_sibling
                else:
                    state.right[old_parent] = next_sibling
                if next_sibling >= 0:
                    state.parents[next_sibling] = old_parent
                state.parents[node] = -1
                state.right[node] = -1
                state.ranks[node] = rph_rank(state.ranks, state.left[node]) + 1

                var ancestor = old_parent
                while ancestor >= 0:
                    if state.parents[ancestor] < 0:
                        state.ranks[ancestor] = rph_rank(state.ranks, state.left[ancestor]) + 1
                        break
                    let left_rank = rph_rank(state.ranks, state.left[ancestor])
                    let right_rank = rph_rank(state.ranks, state.right[ancestor])
                    let new_rank = max(left_rank, right_rank) if left_rank != right_rank else left_rank + 1
                    if new_rank >= state.ranks[ancestor]:
                        break
                    state.ranks[ancestor] = new_rank
                    ancestor = state.parents[ancestor]
        elif opcode == 3:
            if item_value != 0 or value != 0:
                return -1
            let root = rph_minimum_root(state)
            if root < 0:
                return -1
            let removed_item = state.items[root]
            result += Int64(operation_index + 1) * (state.keys[root] + 1) + Int64(removed_item)
            state.active[removed_item] = False
            state.item_nodes[removed_item] = -1

            var child = state.left[root]
            while child >= 0:
                let next_sibling = state.right[child]
                state.right[child] = -1
                state.parents[child] = -1
                state.ranks[child] = rph_rank(state.ranks, state.left[child]) + 1
                child = next_sibling
            state.alive[root] = False
            state.parents[root] = -2
            state.left[root] = -1
            state.right[root] = -1
            state.items[root] = -1
            rph_consolidate(state)
        elif opcode == 4:
            if item_value != 0 or value != 0:
                return -1
            let root = rph_minimum_root(state)
            if root < 0:
                return -1
            result += Int64(operation_index + 1) * (state.keys[root] + 1) + Int64(state.items[root])
        else:
            return -1
    return result
