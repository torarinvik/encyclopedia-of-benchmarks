from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

comptime MAX_OPERATIONS = 64
comptime MAX_ITEMS = 32
comptime MAX_NODES = 64
comptime MAX_KEY: Int64 = 1000000

struct QueueNode:
    var key: Int64
    var serial: Int64
    var item_id: Int
    var rank: Int
    var first_child: Int
    var next_sibling: Int
    var parent: Int
    var alive: Bool

struct SkewQueue:
    var nodes: InlineArray[QueueNode, 64]
    var active: InlineArray[Bool, 32]
    var node_count: Int
    var next_serial: Int64

    fn __init__(out self):
        self.nodes = InlineArray[QueueNode, 64](fill=QueueNode(0, 0, -1, 0, -1, -1, -2, False))
        self.active = InlineArray[Bool, 32](fill=False)
        self.node_count = 0
        self.next_serial = 0

fn queue_less(state: SkewQueue, first: Int, second: Int) -> Bool:
    let a = state.nodes[first]
    let b = state.nodes[second]
    if a.key != b.key: return a.key < b.key
    if a.serial != b.serial: return a.serial < b.serial
    if a.item_id != b.item_id: return a.item_id < b.item_id
    return first < second

fn root_before(state: SkewQueue, first: Int, second: Int) -> Bool:
    let a = state.nodes[first]
    let b = state.nodes[second]
    if a.rank != b.rank: return a.rank < b.rank
    if a.serial != b.serial: return a.serial < b.serial
    return first < second

fn collect_roots(state: SkewQueue, inout roots: InlineArray[Int, 64]) -> Int:
    var count = 0
    for node in range(state.node_count):
        if state.nodes[node].alive and state.nodes[node].parent == -1:
            var position = count
            while position > 0 and root_before(state, node, roots[position - 1]):
                roots[position] = roots[position - 1]
                position -= 1
            roots[position] = node
            count += 1
    return count

fn simple_link(inout state: SkewQueue, first: Int, second: Int) -> Int:
    var winner = first
    var loser = second
    if not queue_less(state, first, second):
        winner = second
        loser = first
    let old_children = state.nodes[winner].first_child
    state.nodes[winner].first_child = loser
    state.nodes[loser].next_sibling = old_children
    state.nodes[loser].parent = winner
    state.nodes[winner].rank += 1
    return winner

fn skew_link(inout state: SkewQueue, singleton: Int, first: Int, second: Int):
    let new_rank = state.nodes[first].rank + 1
    var winner = first
    var loser = second
    if queue_less(state, singleton, first) and queue_less(state, singleton, second):
        winner = singleton
        state.nodes[winner].first_child = first
        state.nodes[first].next_sibling = second
        state.nodes[second].next_sibling = -1
        state.nodes[first].parent = winner
        state.nodes[second].parent = winner
    else:
        if not queue_less(state, first, second):
            winner = second
            loser = first
        let old_children = state.nodes[winner].first_child
        state.nodes[winner].first_child = singleton
        state.nodes[singleton].next_sibling = loser
        state.nodes[loser].next_sibling = old_children
        state.nodes[singleton].parent = winner
        state.nodes[loser].parent = winner
    state.nodes[winner].parent = -1
    state.nodes[winner].rank = new_rank

fn insert_singleton(inout state: SkewQueue, singleton: Int):
    state.nodes[singleton].parent = -2
    var roots = InlineArray[Int, 64](fill=0)
    let root_count = collect_roots(state, inout roots)
    state.nodes[singleton].next_sibling = -1
    if root_count >= 2 and state.nodes[roots[0]].rank == state.nodes[roots[1]].rank:
        skew_link(inout state, singleton, roots[0], roots[1])
    else:
        state.nodes[singleton].parent = -1

fn normalize_roots(inout state: SkewQueue, inout roots: InlineArray[Int, 64], count: Int):
    for index in range(1, count):
        let key = roots[index]
        var position = index
        while position > 0 and root_before(state, key, roots[position - 1]):
            roots[position] = roots[position - 1]
            position -= 1
        roots[position] = key
    var buckets = InlineArray[Int, 64](fill=-1)
    for index in range(count):
        var current = roots[index]
        var rank = state.nodes[current].rank
        while buckets[rank] >= 0:
            let previous = buckets[rank]
            buckets[rank] = -1
            current = simple_link(inout state, previous, current)
            rank = state.nodes[current].rank
        buckets[rank] = current

fn minimum_root(state: SkewQueue) -> Int:
    var best = -1
    for node in range(state.node_count):
        if state.nodes[node].alive and state.nodes[node].parent == -1 and (best < 0 or queue_less(state, node, best)):
            best = node
    return best

fn delete_min(inout state: SkewQueue, root: Int):
    var zero_rank = InlineArray[Int, 64](fill=0)
    var positive = InlineArray[Int, 64](fill=0)
    var zero_count = 0
    var positive_count = 0
    var child = state.nodes[root].first_child
    while child >= 0:
        let next = state.nodes[child].next_sibling
        state.nodes[child].parent = -2
        state.nodes[child].next_sibling = -1
        if state.nodes[child].rank == 0:
            zero_rank[zero_count] = child
            zero_count += 1
        else:
            positive[positive_count] = child
            positive_count += 1
        child = next
    let item_id = state.nodes[root].item_id
    state.active[item_id] = False
    state.nodes[root].alive = False
    state.nodes[root].parent = -2
    state.nodes[root].item_id = -1
    state.nodes[root].first_child = -1
    state.nodes[root].next_sibling = -1

    for index in range(1, zero_count):
        let key = zero_rank[index]
        var position = index
        while position > 0:
            let previous = zero_rank[position - 1]
            if state.nodes[previous].serial < state.nodes[key].serial or (state.nodes[previous].serial == state.nodes[key].serial and previous < key):
                break
            zero_rank[position] = previous
            position -= 1
        zero_rank[position] = key

    var roots = InlineArray[Int, 64](fill=0)
    var root_count = collect_roots(state, inout roots)
    for index in range(positive_count):
        state.nodes[positive[index]].parent = -1
        roots[root_count] = positive[index]
        root_count += 1
    normalize_roots(inout state, inout roots, root_count)
    for index in range(zero_count):
        insert_singleton(inout state, zero_rank[index])

@export("skew_binomial_queue")
fn skew_binomial_queue(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > 194:
        return -1
    let operation_count_value = input[0]
    if operation_count_value < 0 or operation_count_value > MAX_OPERATIONS:
        return -1
    let operation_count = Int(operation_count_value)
    if length != c_size_t(1 + 3 * operation_count) or length > 193:
        return -1
    var state = SkewQueue()
    var result: Int64 = 0
    for operation in range(operation_count):
        let offset = 1 + 3 * operation
        let opcode = input[offset]
        let item_value = input[offset + 1]
        let key = input[offset + 2]
        if opcode == 1:
            if item_value < 0 or item_value >= MAX_ITEMS or key < 0 or key > MAX_KEY:
                return -1
            let item_id = Int(item_value)
            if state.active[item_id] or state.node_count >= MAX_NODES:
                return -1
            let node = state.node_count
            state.node_count += 1
            state.nodes[node] = QueueNode(key, state.next_serial, item_id, 0, -1, -1, -2, True)
            state.next_serial += 1
            state.active[item_id] = True
            insert_singleton(inout state, node)
        elif opcode == 2 or opcode == 3:
            if item_value != 0 or key != 0:
                return -1
            let root = minimum_root(state)
            if root < 0:
                return -1
            result += Int64(operation + 1) * (state.nodes[root].key + 1) + Int64(state.nodes[root].item_id)
            if opcode == 3:
                delete_min(inout state, root)
        else:
            return -1
    return result
