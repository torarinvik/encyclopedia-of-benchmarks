from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

alias MAX_VERTICES = 16
alias MAX_EVENTS = 64
alias MAX_INPUT_VALUES = 2 + 4 * MAX_EVENTS + 1
alias TREE_NODES = 4 * MAX_EVENTS + 8

fn odb_add_interval(node: Int, left: Int, right: Int, query_left: Int,
    query_right: Int, edge_id: Int,
    mut bucket_count: InlineArray[Int, TREE_NODES],
    mut buckets: InlineArray[Int, TREE_NODES * MAX_EVENTS]):
    if query_left <= left and right <= query_right:
        buckets[node * MAX_EVENTS + bucket_count[node]] = edge_id
        bucket_count[node] += 1
        return
    let middle = left + (right - left) // 2
    if query_left < middle:
        odb_add_interval(2 * node, left, middle, query_left, query_right,
            edge_id, mut bucket_count, mut buckets)
    if query_right > middle:
        odb_add_interval(2 * node + 1, middle, right, query_left, query_right,
            edge_id, mut bucket_count, mut buckets)

fn odb_constrain_opposite(left: Int, right: Int,
    mut parent: InlineArray[Int, MAX_VERTICES],
    mut set_size: InlineArray[Int, MAX_VERTICES],
    mut xor_parent: InlineArray[Int, MAX_VERTICES],
    mut history_kind: InlineArray[Int, MAX_EVENTS],
    mut history_child: InlineArray[Int, MAX_EVENTS],
    mut history_root: InlineArray[Int, MAX_EVENTS],
    mut history_size: InlineArray[Int, MAX_EVENTS],
    mut history_xor: InlineArray[Int, MAX_EVENTS], mut history_count: Int,
    mut contradictions: Int):
    var root_left = left
    var root_right = right
    var parity_left = 0
    var parity_right = 0
    while parent[root_left] != root_left:
        parity_left = parity_left ^ xor_parent[root_left]
        root_left = parent[root_left]
    while parent[root_right] != root_right:
        parity_right = parity_right ^ xor_parent[root_right]
        root_right = parent[root_right]
    if root_left == root_right:
        if (parity_left ^ parity_right) != 1:
            history_kind[history_count] = 1
            history_count += 1
            contradictions += 1
        return
    if set_size[root_left] > set_size[root_right]:
        let temporary = root_left
        root_left = root_right
        root_right = temporary
    history_kind[history_count] = 0
    history_child[history_count] = root_left
    history_root[history_count] = root_right
    history_size[history_count] = set_size[root_right]
    history_xor[history_count] = xor_parent[root_left]
    history_count += 1
    parent[root_left] = root_right
    xor_parent[root_left] = parity_left ^ parity_right ^ 1
    set_size[root_right] += set_size[root_left]

fn odb_rollback(checkpoint: Int,
    mut parent: InlineArray[Int, MAX_VERTICES],
    mut set_size: InlineArray[Int, MAX_VERTICES],
    mut xor_parent: InlineArray[Int, MAX_VERTICES],
    history_kind: InlineArray[Int, MAX_EVENTS],
    history_child: InlineArray[Int, MAX_EVENTS],
    history_root: InlineArray[Int, MAX_EVENTS],
    history_size: InlineArray[Int, MAX_EVENTS],
    history_xor: InlineArray[Int, MAX_EVENTS], mut history_count: Int,
    mut contradictions: Int):
    while history_count > checkpoint:
        history_count -= 1
        let entry = history_count
        if history_kind[entry] == 1:
            contradictions -= 1
        else:
            let child = history_child[entry]
            let root = history_root[entry]
            parent[child] = child
            xor_parent[child] = history_xor[entry]
            set_size[root] = history_size[entry]

fn odb_solve_time_tree(node: Int, left: Int, right: Int,
    operation: InlineArray[Int64, MAX_EVENTS],
    edge_left: InlineArray[Int64, MAX_EVENTS],
    edge_right: InlineArray[Int64, MAX_EVENTS],
    bucket_count: InlineArray[Int, TREE_NODES],
    buckets: InlineArray[Int, TREE_NODES * MAX_EVENTS],
    mut parent: InlineArray[Int, MAX_VERTICES],
    mut set_size: InlineArray[Int, MAX_VERTICES],
    mut xor_parent: InlineArray[Int, MAX_VERTICES],
    mut history_kind: InlineArray[Int, MAX_EVENTS],
    mut history_child: InlineArray[Int, MAX_EVENTS],
    mut history_root: InlineArray[Int, MAX_EVENTS],
    mut history_size: InlineArray[Int, MAX_EVENTS],
    mut history_xor: InlineArray[Int, MAX_EVENTS], mut history_count: Int,
    mut contradictions: Int, mut answer: InlineArray[Int64, MAX_EVENTS]):
    let checkpoint = history_count
    for entry in range(bucket_count[node]):
        let edge_id = buckets[node * MAX_EVENTS + entry]
        odb_constrain_opposite(Int(edge_left[edge_id]), Int(edge_right[edge_id]),
            mut parent, mut set_size, mut xor_parent, mut history_kind,
            mut history_child, mut history_root, mut history_size, mut history_xor,
            mut history_count, mut contradictions)
    if right - left == 1:
        if operation[left] == 2:
            answer[left] = 1 if contradictions == 0 else 0
    else:
        let middle = left + (right - left) // 2
        odb_solve_time_tree(2 * node, left, middle, operation, edge_left,
            edge_right, bucket_count, buckets, mut parent, mut set_size,
            mut xor_parent, mut history_kind, mut history_child, mut history_root,
            mut history_size, mut history_xor, mut history_count, mut contradictions,
            mut answer)
        odb_solve_time_tree(2 * node + 1, middle, right, operation, edge_left,
            edge_right, bucket_count, buckets, mut parent, mut set_size,
            mut xor_parent, mut history_kind, mut history_child, mut history_root,
            mut history_size, mut history_xor, mut history_count, mut contradictions,
            mut answer)
    odb_rollback(checkpoint, mut parent, mut set_size, mut xor_parent,
        history_kind, history_child, history_root, history_size, history_xor,
        mut history_count, mut contradictions)

fn odb_store_i64_le(output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int, value: Int64):
    let bits = bitcast[UInt64](value)
    for byte in range(8):
        output[offset + byte] = UInt8((bits >> UInt(8 * byte)) & 255)

@export("offline_dynamic_bipartiteness")
fn offline_dynamic_bipartiteness(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t,
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > MAX_INPUT_VALUES:
        return -1
    let vertex_value = input[0]
    let event_value = input[1]
    if vertex_value < 1 or vertex_value > MAX_VERTICES or event_value < 0 or event_value > MAX_EVENTS:
        return -1
    let vertex_count = Int(vertex_value)
    let event_count = Int(event_value)
    if length != c_size_t(2 + 4 * event_count):
        return -1

    var operation = InlineArray[Int64, MAX_EVENTS]()
    var first = InlineArray[Int64, MAX_EVENTS]()
    var second = InlineArray[Int64, MAX_EVENTS]()
    var edge_left = InlineArray[Int64, MAX_EVENTS]()
    var edge_right = InlineArray[Int64, MAX_EVENTS]()
    var start_time = InlineArray[Int, MAX_EVENTS]()
    var used_id = InlineArray[Int, MAX_EVENTS]()
    var active = InlineArray[Int, MAX_EVENTS]()
    var query_count = 0
    for time in range(event_count):
        let offset = 2 + 4 * time
        operation[time] = input[offset]
        first[time] = input[offset + 1]
        second[time] = input[offset + 2]
        let third = input[offset + 3]
        if operation[time] == 0:
            let edge_id = first[time]
            if edge_id < 0 or edge_id >= MAX_EVENTS or second[time] < 0 or
                second[time] > third or third >= vertex_count:
                return -1
            let id = Int(edge_id)
            if used_id[id] != 0:
                return -1
            for prior in range(MAX_EVENTS):
                if active[prior] != 0 and edge_left[prior] == second[time] and edge_right[prior] == third:
                    return -1
            used_id[id] = 1
            active[id] = 1
            start_time[id] = time
            edge_left[id] = second[time]
            edge_right[id] = third
        elif operation[time] == 1:
            let edge_id = first[time]
            if edge_id < 0 or edge_id >= MAX_EVENTS or second[time] != 0 or third != 0:
                return -1
            let id = Int(edge_id)
            if active[id] == 0:
                return -1
            active[id] = 0
        elif operation[time] == 2:
            if first[time] != 0 or second[time] != 0 or third != 0:
                return -1
            query_count += 1
        else:
            return -1

    let required = 8 * query_count
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(required):
        return -2
    var bucket_count = InlineArray[Int, TREE_NODES]()
    var buckets = InlineArray[Int, TREE_NODES * MAX_EVENTS]()
    for edge_id in range(MAX_EVENTS):
        if used_id[edge_id] == 0:
            continue
        var end_time = event_count
        if active[edge_id] == 0:
            for time in range(start_time[edge_id] + 1, event_count):
                if operation[time] == 1 and first[time] == Int64(edge_id):
                    end_time = time
                    break
        if start_time[edge_id] < end_time and event_count != 0:
            odb_add_interval(1, 0, event_count, start_time[edge_id], end_time,
                edge_id, mut bucket_count, mut buckets)

    var parent = InlineArray[Int, MAX_VERTICES]()
    var set_size = InlineArray[Int, MAX_VERTICES]()
    var xor_parent = InlineArray[Int, MAX_VERTICES]()
    for vertex in range(vertex_count):
        parent[vertex] = vertex
        set_size[vertex] = 1
    var history_kind = InlineArray[Int, MAX_EVENTS]()
    var history_child = InlineArray[Int, MAX_EVENTS]()
    var history_root = InlineArray[Int, MAX_EVENTS]()
    var history_size = InlineArray[Int, MAX_EVENTS]()
    var history_xor = InlineArray[Int, MAX_EVENTS]()
    var history_count = 0
    var contradictions = 0
    var answer = InlineArray[Int64, MAX_EVENTS]()
    if event_count != 0:
        odb_solve_time_tree(1, 0, event_count, operation, edge_left, edge_right,
            bucket_count, buckets, mut parent, mut set_size, mut xor_parent,
            mut history_kind, mut history_child, mut history_root, mut history_size,
            mut history_xor, mut history_count, mut contradictions, mut answer)

    var written = 0
    for time in range(event_count):
        if operation[time] == 2:
            odb_store_i64_le(output, written, answer[time])
            written += 8
    return Int64(written)
