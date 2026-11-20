from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

comptime MAX_N = 32
comptime MAX_Q = 32
comptime MAX_INPUT = 3 * MAX_N + 2 * MAX_Q

struct Query(Copyable):
    var left: Int
    var right: Int
    var id: Int
    var block: Int
    var right_key: Int
    var extra: Int

fn find_root(mut parent: InlineArray[Int, MAX_N], item: Int) -> Int:
    var node = item
    while parent[node] != node:
        parent[node] = parent[parent[node]]
        node = parent[node]
    return node

fn query_less(a: Query, b: Query) -> Bool:
    if a.block != b.block: return a.block < b.block
    if a.right_key != b.right_key: return a.right_key < b.right_key
    return a.id < b.id

fn sift_down(mut values: InlineArray[Query, MAX_Q], root_start: Int, end: Int):
    var root = root_start
    while root * 2 + 1 < end:
        let child = root * 2 + 1
        var largest = root
        if query_less(values[largest], values[child]): largest = child
        if child + 1 < end and query_less(values[largest], values[child + 1]):
            largest = child + 1
        if largest == root: return
        let temporary = values[root]
        values[root] = values[largest]
        values[largest] = temporary
        root = largest

fn heap_sort(mut values: InlineArray[Query, MAX_Q], length: Int):
    var start = length // 2
    while start > 0:
        start -= 1
        sift_down(mut values, start, length)
    var end = length
    while end > 1:
        end -= 1
        let temporary = values[0]
        values[0] = values[end]
        values[end] = temporary
        sift_down(mut values, 0, end)

fn lca(a_raw: Int, b_raw: Int, parent: InlineArray[Int, MAX_N],
       depth: InlineArray[Int, MAX_N]) -> Int:
    var a = a_raw
    var b = b_raw
    while depth[a] > depth[b]: a = parent[a]
    while depth[b] > depth[a]: b = parent[b]
    while a != b:
        a = parent[a]
        b = parent[b]
    return a

fn toggle(vertex: Int, color_id: InlineArray[Int, MAX_N],
          mut counts: InlineArray[Int, MAX_N],
          mut active: InlineArray[Bool, MAX_N], mut distinct: Int):
    let color = color_id[vertex]
    if active[vertex]:
        active[vertex] = False
        counts[color] -= 1
        if counts[color] == 0: distinct -= 1
    else:
        active[vertex] = True
        if counts[color] == 0: distinct += 1
        counts[color] += 1

fn store_le(output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int, value: Int64):
    let bits = bitcast[UInt64](value)
    for byte in range(8):
        output[offset + byte] = UInt8((bits >> (8 * byte)) & UInt64(255))

@export("tree_path_distinct_mo")
fn tree_path_distinct_mo(
    input: UnsafePointer[Int64, ImmutAnyOrigin],
    length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin],
    capacity: c_size_t,
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3 or length > MAX_INPUT + 1:
        return -1
    let n_value = input[0]
    let q_value = input[1]
    if n_value < 1 or n_value > MAX_N or q_value < 0 or q_value > MAX_Q:
        return -1
    let n = Int(n_value)
    let q = Int(q_value)
    if Int(length) != 3 * n + 2 * q:
        return -1

    var colors = InlineArray[Int64, MAX_N]()
    for vertex in range(n): colors[vertex] = input[2 + vertex]
    var adjacent = InlineArray[Bool, MAX_N * MAX_N](fill=False)
    var dsu_parent = InlineArray[Int, MAX_N]()
    var dsu_size = InlineArray[Int, MAX_N]()
    for vertex in range(n):
        dsu_parent[vertex] = vertex
        dsu_size[vertex] = 1
    var offset = 2 + n
    for _ in range(n - 1):
        let u_value = input[offset]
        let v_value = input[offset + 1]
        offset += 2
        if u_value < 0 or u_value >= n_value or v_value < 0 or v_value >= n_value or u_value == v_value:
            return -1
        let u = Int(u_value)
        let v = Int(v_value)
        var root_u = find_root(mut dsu_parent, u)
        var root_v = find_root(mut dsu_parent, v)
        if root_u == root_v: return -1
        if dsu_size[root_u] < dsu_size[root_v]:
            let temporary = root_u
            root_u = root_v
            root_v = temporary
        dsu_parent[root_v] = root_u
        dsu_size[root_u] += dsu_size[root_v]
        adjacent[u * MAX_N + v] = True
        adjacent[v * MAX_N + u] = True

    var query_u = InlineArray[Int, MAX_Q]()
    var query_v = InlineArray[Int, MAX_Q]()
    for id in range(q):
        let u_value = input[offset]
        let v_value = input[offset + 1]
        offset += 2
        if u_value < 0 or u_value >= n_value or v_value < 0 or v_value >= n_value:
            return -1
        query_u[id] = Int(u_value)
        query_v[id] = Int(v_value)

    var color_id = InlineArray[Int, MAX_N]()
    var first_color = InlineArray[Int, MAX_N]()
    var color_count = 0
    for vertex in range(n):
        var rank = 0
        while rank < color_count and colors[first_color[rank]] != colors[vertex]: rank += 1
        if rank == color_count:
            first_color[color_count] = vertex
            color_count += 1
        color_id[vertex] = rank

    var parent = InlineArray[Int, MAX_N]()
    var depth = InlineArray[Int, MAX_N]()
    var entry = InlineArray[Int, MAX_N]()
    var leave = InlineArray[Int, MAX_N]()
    var euler = InlineArray[Int, 2 * MAX_N]()
    var event_node = InlineArray[Int, 2 * MAX_N]()
    var event_parent = InlineArray[Int, 2 * MAX_N]()
    var event_exit = InlineArray[Bool, 2 * MAX_N](fill=False)
    var top = 1
    var clock = 0
    event_node[0] = 0
    event_parent[0] = n
    while top > 0:
        top -= 1
        let u = event_node[top]
        let previous = event_parent[top]
        if event_exit[top]:
            leave[u] = clock
            euler[clock] = u
            clock += 1
        else:
            parent[u] = previous
            entry[u] = clock
            euler[clock] = u
            clock += 1
            event_node[top] = u
            event_parent[top] = previous
            event_exit[top] = True
            top += 1
            var v = n
            while v > 0:
                v -= 1
                if adjacent[u * MAX_N + v] and v != previous:
                    depth[v] = depth[u] + 1
                    event_node[top] = v
                    event_parent[top] = u
                    event_exit[top] = False
                    top += 1

    var queries = InlineArray[Query, MAX_Q]()
    var block_size = 1
    while (block_size + 1) * (block_size + 1) <= 2 * n: block_size += 1
    for id in range(q):
        var u = query_u[id]
        var v = query_v[id]
        if entry[u] > entry[v]:
            let temporary = u
            u = v
            v = temporary
        let ancestor = lca(u, v, parent, depth)
        let left = entry[u] if ancestor == u else leave[u]
        let right = entry[v]
        let block = left // block_size
        let right_key = right if block % 2 == 0 else 2 * n - 1 - right
        let extra = -1 if ancestor == u else ancestor
        queries[id] = Query(left, right, id, block, right_key, extra)
    heap_sort(mut queries, q)

    var counts = InlineArray[Int, MAX_N]()
    var active = InlineArray[Bool, MAX_N](fill=False)
    var answers = InlineArray[Int, MAX_Q]()
    var distinct = 0
    var left = 0
    var right = -1
    for sorted_id in range(q):
        let query = queries[sorted_id]
        while left > query.left:
            left -= 1
            toggle(euler[left], color_id, mut counts, mut active, mut distinct)
        while right < query.right:
            right += 1
            toggle(euler[right], color_id, mut counts, mut active, mut distinct)
        while left < query.left:
            toggle(euler[left], color_id, mut counts, mut active, mut distinct)
            left += 1
        while right > query.right:
            toggle(euler[right], color_id, mut counts, mut active, mut distinct)
            right -= 1
        if query.extra >= 0:
            toggle(query.extra, color_id, mut counts, mut active, mut distinct)
            answers[query.id] = distinct
            toggle(query.extra, color_id, mut counts, mut active, mut distinct)
        else:
            answers[query.id] = distinct

    let required = 8 * q
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or Int(capacity) < required:
        return -2
    for id in range(q): store_le(output, 8 * id, Int64(answers[id]))
    return Int64(required)
