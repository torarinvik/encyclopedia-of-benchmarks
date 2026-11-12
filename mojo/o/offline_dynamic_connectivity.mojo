from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

alias MAX_VERTICES = 16
alias MAX_EVENTS = 32
alias MAX_INPUT_VALUES = 2 + 4 * MAX_EVENTS + 1
alias TREE_NODES = 4 * MAX_EVENTS + 8

fn odc_find_root(parent: InlineArray[Int, MAX_VERTICES], vertex_input: Int) -> Int:
    var vertex = vertex_input
    while parent[vertex] != vertex:
        vertex = parent[vertex]
    return vertex

fn odc_add_interval(node: Int, left: Int, right: Int, query_left: Int,
    query_right: Int, edge_id: Int,
    mut bucket_count: InlineArray[Int, TREE_NODES],
    mut buckets: InlineArray[Int, TREE_NODES * MAX_EVENTS]):
    if query_left <= left and right <= query_right:
        buckets[node * MAX_EVENTS + bucket_count[node]] = edge_id
        bucket_count[node] += 1
        return
    let middle = left + (right - left) // 2
    if query_left < middle:
        odc_add_interval(2 * node, left, middle, query_left, query_right,
            edge_id, mut bucket_count, mut buckets)
    if query_right > middle:
        odc_add_interval(2 * node + 1, middle, right, query_left, query_right,
            edge_id, mut bucket_count, mut buckets)

fn odc_unite(left: Int, right: Int, mut parent: InlineArray[Int, MAX_VERTICES],
    mut set_size: InlineArray[Int, MAX_VERTICES],
    mut history_child: InlineArray[Int, MAX_VERTICES],
    mut history_root: InlineArray[Int, MAX_VERTICES],
    mut history_size: InlineArray[Int, MAX_VERTICES], mut history_count: Int):
    var root_left = odc_find_root(parent, left)
    var root_right = odc_find_root(parent, right)
    if root_left == root_right:
        return
    if set_size[root_left] > set_size[root_right]:
        let temporary = root_left
        root_left = root_right
        root_right = temporary
    history_child[history_count] = root_left
    history_root[history_count] = root_right
    history_size[history_count] = set_size[root_right]
    history_count += 1
    parent[root_left] = root_right
    set_size[root_right] += set_size[root_left]

fn odc_rollback(checkpoint: Int, mut parent: InlineArray[Int, MAX_VERTICES],
    mut set_size: InlineArray[Int, MAX_VERTICES],
    history_child: InlineArray[Int, MAX_VERTICES],
    history_root: InlineArray[Int, MAX_VERTICES],
    history_size: InlineArray[Int, MAX_VERTICES], mut history_count: Int):
    while history_count > checkpoint:
        history_count -= 1
        let child = history_child[history_count]
        let root = history_root[history_count]
        parent[child] = child
        set_size[root] = history_size[history_count]

fn odc_solve_time_tree(node: Int, left: Int, right: Int,
    operation: InlineArray[Int64, MAX_EVENTS],
    first: InlineArray[Int64, MAX_EVENTS],
    second: InlineArray[Int64, MAX_EVENTS],
    edge_left: InlineArray[Int64, MAX_EVENTS],
    edge_right: InlineArray[Int64, MAX_EVENTS],
    bucket_count: InlineArray[Int, TREE_NODES],
    buckets: InlineArray[Int, TREE_NODES * MAX_EVENTS],
    mut parent: InlineArray[Int, MAX_VERTICES],
    mut set_size: InlineArray[Int, MAX_VERTICES],
    mut history_child: InlineArray[Int, MAX_VERTICES],
    mut history_root: InlineArray[Int, MAX_VERTICES],
    mut history_size: InlineArray[Int, MAX_VERTICES], mut history_count: Int,
    mut answer: InlineArray[Int64, MAX_EVENTS]):
    let checkpoint = history_count
    for entry in range(bucket_count[node]):
        let edge_id = buckets[node * MAX_EVENTS + entry]
        odc_unite(Int(edge_left[edge_id]), Int(edge_right[edge_id]), mut parent,
            mut set_size, mut history_child, mut history_root, mut history_size,
            mut history_count)
    if right - left == 1:
        if operation[left] == 2:
            if odc_find_root(parent, Int(first[left])) == odc_find_root(parent, Int(second[left])):
                answer[left] = 1
            else:
                answer[left] = 0
    else:
        let middle = left + (right - left) // 2
        odc_solve_time_tree(2 * node, left, middle, operation, first, second,
            edge_left, edge_right, bucket_count, buckets, mut parent, mut set_size,
            mut history_child, mut history_root, mut history_size, mut history_count,
            mut answer)
        odc_solve_time_tree(2 * node + 1, middle, right, operation, first, second,
            edge_left, edge_right, bucket_count, buckets, mut parent, mut set_size,
            mut history_child, mut history_root, mut history_size, mut history_count,
            mut answer)
    odc_rollback(checkpoint, mut parent, mut set_size, history_child,
        history_root, history_size, mut history_count)

fn odc_store_i64_le(output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int, value: Int64):
    let bits = bitcast[UInt64](value)
    for byte in range(8):
        output[offset + byte] = UInt8((bits >> UInt(8 * byte)) & 255)

@export("offline_dynamic_connectivity")
fn offline_dynamic_connectivity(
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
                second[time] >= vertex_count or third < 0 or third >= vertex_count:
                return -1
            let id = Int(edge_id)
            if used_id[id] != 0:
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
            if first[time] < 0 or first[time] >= vertex_count or
                second[time] < 0 or second[time] >= vertex_count or third != 0:
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
            var time = start_time[edge_id] + 1
            while time < event_count:
                if operation[time] == 1 and first[time] == Int64(edge_id):
                    end_time = time
                    break
                time += 1
        if start_time[edge_id] < end_time and event_count != 0:
            odc_add_interval(1, 0, event_count, start_time[edge_id], end_time,
                edge_id, mut bucket_count, mut buckets)

    var parent = InlineArray[Int, MAX_VERTICES]()
    var set_size = InlineArray[Int, MAX_VERTICES]()
    for vertex in range(vertex_count):
        parent[vertex] = vertex
        set_size[vertex] = 1
    var history_child = InlineArray[Int, MAX_VERTICES]()
    var history_root = InlineArray[Int, MAX_VERTICES]()
    var history_size = InlineArray[Int, MAX_VERTICES]()
    var history_count = 0
    var answer = InlineArray[Int64, MAX_EVENTS]()
    if event_count != 0:
        odc_solve_time_tree(1, 0, event_count, operation, first, second,
            edge_left, edge_right, bucket_count, buckets, mut parent, mut set_size,
            mut history_child, mut history_root, mut history_size, mut history_count,
            mut answer)

    var written = 0
    for time in range(event_count):
        if operation[time] == 2:
            odc_store_i64_le(output, written, answer[time])
            written += 8
    return Int64(written)
