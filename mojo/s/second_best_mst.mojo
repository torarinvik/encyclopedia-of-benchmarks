from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

comptime MAX_N = 8
comptime MAX_M = 20

fn second_best_mst_store(output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int, value: Int64):
    let bits = bitcast[UInt64](value)
    for byte in range(8):
        output[offset + byte] = UInt8((bits >> UInt(8 * byte)) & 255)

@export("second_best_mst")
fn second_best_mst(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 2 + 3 * MAX_M:
        return -1
    let n_value = input[0]
    let m_value = input[1]
    if n_value < 1 or n_value > MAX_N or m_value < n_value - 1 or m_value > MAX_M:
        return -1
    let n = Int(n_value)
    let m = Int(m_value)
    if length != c_size_t(2 + 3 * m):
        return -1

    var edge_u = InlineArray[Int, MAX_M]()
    var edge_v = InlineArray[Int, MAX_M]()
    var edge_weight = InlineArray[Int64, MAX_M]()
    var order = InlineArray[Int, MAX_M]()
    var seen = InlineArray[Bool, MAX_N * MAX_N]()
    for edge in range(m):
        let u_value = input[2 + 3 * edge]
        let v_value = input[3 + 3 * edge]
        let weight = input[4 + 3 * edge]
        if u_value < 0 or u_value >= v_value or v_value >= n_value or weight < 0 or weight > 1_000_000:
            return -1
        let u = Int(u_value)
        let v = Int(v_value)
        if seen[u * MAX_N + v]:
            return -1
        seen[u * MAX_N + v] = True
        edge_u[edge] = u
        edge_v[edge] = v
        edge_weight[edge] = weight
        order[edge] = edge

    for i in range(1, m):
        let edge = order[i]
        var j = i
        while j > 0 and (edge_weight[order[j - 1]] > edge_weight[edge]
            or (edge_weight[order[j - 1]] == edge_weight[edge] and order[j - 1] > edge)):
            order[j] = order[j - 1]
            j -= 1
        order[j] = edge

    var dsu = InlineArray[Int, MAX_N]()
    var component_size = InlineArray[Int, MAX_N]()
    for vertex in range(n):
        dsu[vertex] = vertex
        component_size[vertex] = 1
    var in_mst = InlineArray[Bool, MAX_M]()
    var tree_to = InlineArray[Int, MAX_N * MAX_N]()
    var tree_edge = InlineArray[Int, MAX_N * MAX_N]()
    var degree = InlineArray[Int, MAX_N]()
    var selected = 0
    var mst_weight: Int64 = 0
    for position in range(m):
        let edge = order[position]
        var root_u = edge_u[edge]
        var root_v = edge_v[edge]
        while dsu[root_u] != root_u:
            dsu[root_u] = dsu[dsu[root_u]]
            root_u = dsu[root_u]
        while dsu[root_v] != root_v:
            dsu[root_v] = dsu[dsu[root_v]]
            root_v = dsu[root_v]
        if root_u == root_v:
            continue
        if component_size[root_u] < component_size[root_v]:
            let temporary = root_u
            root_u = root_v
            root_v = temporary
        dsu[root_v] = root_u
        component_size[root_u] += component_size[root_v]
        in_mst[edge] = True
        selected += 1
        mst_weight += edge_weight[edge]
        let cell_u = edge_u[edge] * MAX_N + degree[edge_u[edge]]
        tree_to[cell_u] = edge_v[edge]
        tree_edge[cell_u] = edge
        degree[edge_u[edge]] += 1
        let cell_v = edge_v[edge] * MAX_N + degree[edge_v[edge]]
        tree_to[cell_v] = edge_u[edge]
        tree_edge[cell_v] = edge
        degree[edge_v[edge]] += 1
    if selected != n - 1:
        return -1

    var second_weight: Int64 = -1
    var entering_edge = -1
    var leaving_edge = -1
    for added in range(m):
        if in_mst[added]:
            continue
        var parent = InlineArray[Int, MAX_N]()
        var parent_edge = InlineArray[Int, MAX_N]()
        var queue = InlineArray[Int, MAX_N]()
        for vertex in range(n):
            parent[vertex] = -1
        var head = 0
        var tail = 0
        let start = edge_u[added]
        let target = edge_v[added]
        parent[start] = start
        queue[tail] = start
        tail += 1
        while head < tail and parent[target] == -1:
            let vertex = queue[head]
            head += 1
            for i in range(degree[vertex]):
                let cell = vertex * MAX_N + i
                let next = tree_to[cell]
                if parent[next] != -1:
                    continue
                parent[next] = vertex
                parent_edge[next] = tree_edge[cell]
                queue[tail] = next
                tail += 1
        var first_weight: Int64 = -1
        var second_path_weight: Int64 = -1
        var first_edge = -1
        var second_path_edge = -1
        var vertex = target
        while vertex != start:
            let path_edge = parent_edge[vertex]
            let weight = edge_weight[path_edge]
            if weight > first_weight:
                second_path_weight = first_weight
                second_path_edge = first_edge
                first_weight = weight
                first_edge = path_edge
            elif weight == first_weight:
                if first_edge < 0 or path_edge < first_edge:
                    first_edge = path_edge
            elif weight > second_path_weight:
                second_path_weight = weight
                second_path_edge = path_edge
            elif weight == second_path_weight and (second_path_edge < 0 or path_edge < second_path_edge):
                second_path_edge = path_edge
            vertex = parent[vertex]
        var removed_weight: Int64 = -1
        var removed_edge = -1
        if edge_weight[added] > first_weight:
            removed_weight = first_weight
            removed_edge = first_edge
        elif edge_weight[added] == first_weight and second_path_weight >= 0:
            removed_weight = second_path_weight
            removed_edge = second_path_edge
        if removed_edge < 0:
            continue
        let candidate = mst_weight + edge_weight[added] - removed_weight
        if second_weight < 0 or candidate < second_weight
            or (candidate == second_weight and (added < entering_edge
                or (added == entering_edge and removed_edge < leaving_edge))):
            second_weight = candidate
            entering_edge = added
            leaving_edge = removed_edge

    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < 32:
        return -2
    second_best_mst_store(output, 0, mst_weight)
    second_best_mst_store(output, 8, second_weight)
    second_best_mst_store(output, 16, Int64(entering_edge))
    second_best_mst_store(output, 24, Int64(leaving_edge))
    return 32
