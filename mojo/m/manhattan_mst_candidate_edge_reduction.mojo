from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

comptime MAX_N = 31
comptime MAX_CANDIDATES = 124
comptime MAX_PARSEABLE_INPUT = 64
comptime TREE_SIZE = 32

fn mm_fenwick_add(inout tree: InlineArray[Int64, 32], n: Int,
        index_input: Int, delta: Int64):
    var index = index_input + 1
    while index <= n:
        tree[index] += delta
        index += index & -index

fn mm_fenwick_sum(tree: InlineArray[Int64, 32], count_input: Int) -> Int64:
    var index = count_input
    var total: Int64 = 0
    while index > 0:
        total += tree[index]
        index -= index & -index
    return total

fn mm_fenwick_select(tree: InlineArray[Int64, 32], n: Int,
        kth_input: Int64) -> Int:
    var index = 0
    var bit = 1
    while bit * 2 <= n:
        bit *= 2
    var kth = kth_input
    while bit > 0:
        let next = index + bit
        if next <= n and tree[next] < kth:
            kth -= tree[next]
            index = next
        bit //= 2
    return index

fn mm_find(inout parent: InlineArray[Int, MAX_N], node_input: Int) -> Int:
    var root = node_input
    while parent[root] != root:
        root = parent[root]
    var current = node_input
    while parent[current] != current:
        let next = parent[current]
        parent[current] = root
        current = next
    return root

fn mm_union(inout parent: InlineArray[Int, MAX_N],
        inout component_size: InlineArray[Int, MAX_N], left: Int,
        right: Int) -> Bool:
    let root_left = mm_find(inout parent, left)
    let root_right = mm_find(inout parent, right)
    if root_left == root_right: return False
    if component_size[root_left] < component_size[root_right]:
        parent[root_left] = root_right
        component_size[root_right] += component_size[root_left]
    else:
        parent[root_right] = root_left
        component_size[root_left] += component_size[root_right]
    return True

fn mm_add_edge(inout edge_u: InlineArray[Int, MAX_CANDIDATES],
        inout edge_v: InlineArray[Int, MAX_CANDIDATES],
        inout edge_weight: InlineArray[Int64, MAX_CANDIDATES],
        inout edge_count: Int, first: Int, second: Int,
        x: InlineArray[Int64, MAX_N], y: InlineArray[Int64, MAX_N]):
    var u = first
    var v = second
    if u > v:
        let temporary = u
        u = v
        v = temporary
    var dx = x[first] - x[second]
    var dy = y[first] - y[second]
    if dx < 0: dx = -dx
    if dy < 0: dy = -dy
    edge_u[edge_count] = u
    edge_v[edge_count] = v
    edge_weight[edge_count] = dx + dy
    edge_count += 1

fn mm_sift_points(inout order: InlineArray[Int, MAX_N],
        inout keys: InlineArray[Int64, MAX_N], size: Int, root_input: Int):
    var root = root_input
    while root * 2 + 1 < size:
        let left = root * 2 + 1
        var largest = root
        let left_point = order[left]
        let largest_point = order[largest]
        if keys[left_point] > keys[largest_point] or (keys[left_point] == keys[largest_point] and left_point > largest_point):
            largest = left
        let right = left + 1
        if right < size:
            let right_point = order[right]
            let current_largest_point = order[largest]
            if keys[right_point] > keys[current_largest_point] or (keys[right_point] == keys[current_largest_point] and right_point > current_largest_point):
                largest = right
        if largest == root: break
        let temporary = order[root]
        order[root] = order[largest]
        order[largest] = temporary
        root = largest

fn mm_sort_points(inout order: InlineArray[Int, MAX_N],
        inout keys: InlineArray[Int64, MAX_N], size: Int):
    if size < 2: return
    var start = size // 2
    while start > 0:
        start -= 1
        mm_sift_points(inout order, inout keys, size, start)
    var finish = size
    while finish > 1:
        finish -= 1
        let temporary = order[0]
        order[0] = order[finish]
        order[finish] = temporary
        mm_sift_points(inout order, inout keys, finish, 0)

fn mm_sift_edges(inout edge_u: InlineArray[Int, MAX_CANDIDATES],
        inout edge_v: InlineArray[Int, MAX_CANDIDATES],
        inout edge_weight: InlineArray[Int64, MAX_CANDIDATES],
        size: Int, root_input: Int):
    var root = root_input
    while root * 2 + 1 < size:
        let left = root * 2 + 1
        var largest = root
        if edge_weight[largest] < edge_weight[left] or (edge_weight[largest] == edge_weight[left] and edge_u[largest] < edge_u[left]) or (edge_weight[largest] == edge_weight[left] and edge_u[largest] == edge_u[left] and edge_v[largest] < edge_v[left]):
            largest = left
        let right = left + 1
        if right < size:
            if edge_weight[largest] < edge_weight[right] or (edge_weight[largest] == edge_weight[right] and edge_u[largest] < edge_u[right]) or (edge_weight[largest] == edge_weight[right] and edge_u[largest] == edge_u[right] and edge_v[largest] < edge_v[right]):
                largest = right
        if largest == root: break
        let temporary_u = edge_u[root]
        let temporary_v = edge_v[root]
        let temporary_weight = edge_weight[root]
        edge_u[root] = edge_u[largest]
        edge_v[root] = edge_v[largest]
        edge_weight[root] = edge_weight[largest]
        edge_u[largest] = temporary_u
        edge_v[largest] = temporary_v
        edge_weight[largest] = temporary_weight
        root = largest

fn mm_sort_edges(inout edge_u: InlineArray[Int, MAX_CANDIDATES],
        inout edge_v: InlineArray[Int, MAX_CANDIDATES],
        inout edge_weight: InlineArray[Int64, MAX_CANDIDATES], size: Int):
    if size < 2: return
    var start = size // 2
    while start > 0:
        start -= 1
        mm_sift_edges(inout edge_u, inout edge_v, inout edge_weight, size, start)
    var finish = size
    while finish > 1:
        finish -= 1
        let temporary_u = edge_u[0]
        let temporary_v = edge_v[0]
        let temporary_weight = edge_weight[0]
        edge_u[0] = edge_u[finish]
        edge_v[0] = edge_v[finish]
        edge_weight[0] = edge_weight[finish]
        edge_u[finish] = temporary_u
        edge_v[finish] = temporary_v
        edge_weight[finish] = temporary_weight
        mm_sift_edges(inout edge_u, inout edge_v, inout edge_weight, finish, 0)

@export("manhattan_mst_candidate_edge_reduction")
fn manhattan_mst_candidate_edge_reduction(input: UnsafePointer[Int64, ImmutAnyOrigin],
        length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > MAX_PARSEABLE_INPUT:
        return -1
    let raw_n = input[0]
    if raw_n < 0 or raw_n > MAX_N: return -1
    let n = Int(raw_n)
    if length != c_size_t(1 + 2 * n): return -1

    var x = InlineArray[Int64, MAX_N](fill=0)
    var y = InlineArray[Int64, MAX_N](fill=0)
    for point in range(n):
        let x_value = input[1 + 2 * point]
        let y_value = input[2 + 2 * point]
        if x_value < -1000 or x_value > 1000 or y_value < -1000 or y_value > 1000:
            return -1
        x[point] = x_value
        y[point] = y_value
    if n < 2: return 0

    var order = InlineArray[Int, MAX_N](fill=0)
    var by_x = InlineArray[Int, MAX_N](fill=0)
    var sort_key = InlineArray[Int64, MAX_N](fill=0)
    var rank_of = InlineArray[Int, MAX_N](fill=0)
    var id_at_rank = InlineArray[Int, MAX_N](fill=0)
    var fenwick = InlineArray[Int64, TREE_SIZE](fill=0)
    var edge_u = InlineArray[Int, MAX_CANDIDATES](fill=0)
    var edge_v = InlineArray[Int, MAX_CANDIDATES](fill=0)
    var edge_weight = InlineArray[Int64, MAX_CANDIDATES](fill=0)
    var edge_count = 0

    for point in range(n):
        order[point] = point
        sort_key[point] = x[point]
    mm_sort_points(inout order, inout sort_key, n)
    for index in range(1, n):
        if x[order[index - 1]] == x[order[index]]: return -1
    for point in range(n): sort_key[point] = y[point]
    mm_sort_points(inout order, inout sort_key, n)
    for index in range(1, n):
        if y[order[index - 1]] == y[order[index]]: return -1

    for direction in range(4):
        for point in range(n):
            order[point] = point
            by_x[point] = point
        for point in range(n): sort_key[point] = x[point] + y[point]
        mm_sort_points(inout order, inout sort_key, n)
        for point in range(n): sort_key[point] = x[point]
        mm_sort_points(inout by_x, inout sort_key, n)
        for rank in range(n):
            let point = by_x[rank]
            rank_of[point] = rank
            id_at_rank[rank] = point
        for index in range(TREE_SIZE): fenwick[index] = 0

        for position in range(n):
            let current = order[position]
            let current_rank = rank_of[current]
            var active_count = mm_fenwick_sum(fenwick, current_rank + 1)
            while active_count > 0:
                let candidate_rank = mm_fenwick_select(fenwick, n, active_count)
                let candidate = id_at_rank[candidate_rank]
                if x[current] - y[current] > x[candidate] - y[candidate]: break
                mm_add_edge(inout edge_u, inout edge_v, inout edge_weight,
                    inout edge_count, current, candidate, x, y)
                mm_fenwick_add(inout fenwick, n, candidate_rank, -1)
                active_count = mm_fenwick_sum(fenwick, current_rank + 1)
            mm_fenwick_add(inout fenwick, n, current_rank, 1)

        if direction % 2 == 0:
            for point in range(n):
                let temporary = x[point]
                x[point] = y[point]
                y[point] = temporary
        else:
            for point in range(n): x[point] = -x[point]

    mm_sort_edges(inout edge_u, inout edge_v, inout edge_weight, edge_count)

    var parent = InlineArray[Int, MAX_N](fill=0)
    var component_size = InlineArray[Int, MAX_N](fill=1)
    for point in range(n): parent[point] = point
    var components = n
    var total: Int64 = 0
    for edge in range(edge_count):
        if mm_union(inout parent, inout component_size, edge_u[edge], edge_v[edge]):
            total += edge_weight[edge]
            components -= 1
            if components == 1: break
    if components != 1: return -1
    return total
