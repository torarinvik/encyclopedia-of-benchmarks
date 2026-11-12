from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

comptime TPC_MAX_N = 32
comptime TPC_MAX_CELLS = 1024
comptime TPC_MAX_INPUT = 157
comptime TPC_MOD: Int64 = 998244353

@export("tree_path_composite_sum")
fn tree_path_composite_sum(
    input: UnsafePointer[Int64, ImmutAnyOrigin],
    length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin],
    capacity: c_size_t,
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > TPC_MAX_INPUT:
        return -1
    let n_value = input[0]
    if n_value < 1 or n_value > TPC_MAX_N:
        return -1
    let n = Int(n_value)
    if Int(length) != 1 + n + 4 * (n - 1):
        return -1

    var vertex_value = InlineArray[Int64, 32]()
    for vertex in range(n):
        vertex_value[vertex] = input[1 + vertex]
        if vertex_value[vertex] < 0 or vertex_value[vertex] >= TPC_MOD:
            return -1
    var adjacent = InlineArray[Bool, 1024]()
    var multiplier = InlineArray[Int64, 1024]()
    var addend = InlineArray[Int64, 1024]()
    var dsu_parent = InlineArray[Int, 32]()
    var dsu_size = InlineArray[Int, 32]()
    for vertex in range(n):
        dsu_parent[vertex] = vertex
        dsu_size[vertex] = 1
    var offset = 1 + n
    for _ in range(n - 1):
        let u_value = input[offset]
        let v_value = input[offset + 1]
        let b = input[offset + 2]
        let c = input[offset + 3]
        offset += 4
        if (
            u_value < 0 or u_value >= n_value or v_value < 0 or v_value >= n_value
            or u_value == v_value or b < 1 or b >= TPC_MOD or c < 0 or c >= TPC_MOD
        ):
            return -1
        let u = Int(u_value)
        let v = Int(v_value)
        var root_u = u
        while dsu_parent[root_u] != root_u:
            dsu_parent[root_u] = dsu_parent[dsu_parent[root_u]]
            root_u = dsu_parent[root_u]
        var root_v = v
        while dsu_parent[root_v] != root_v:
            dsu_parent[root_v] = dsu_parent[dsu_parent[root_v]]
            root_v = dsu_parent[root_v]
        if root_u == root_v:
            return -1
        if dsu_size[root_u] < dsu_size[root_v]:
            let temporary = root_u
            root_u = root_v
            root_v = temporary
        dsu_parent[root_v] = root_u
        dsu_size[root_u] += dsu_size[root_v]
        adjacent[u * TPC_MAX_N + v] = True
        adjacent[v * TPC_MAX_N + u] = True
        multiplier[u * TPC_MAX_N + v] = b
        multiplier[v * TPC_MAX_N + u] = b
        addend[u * TPC_MAX_N + v] = c
        addend[v * TPC_MAX_N + u] = c

    var order = InlineArray[Int, 32]()
    var stack = InlineArray[Int, 32]()
    var parent = InlineArray[Int, 32]()
    for vertex in range(n):
        parent[vertex] = -2
    parent[0] = -1
    var top = 1
    var order_count = 0
    stack[0] = 0
    while top > 0:
        top -= 1
        let u = stack[top]
        order[order_count] = u
        order_count += 1
        for v in range(n):
            let cell = u * TPC_MAX_N + v
            if adjacent[cell] and v != parent[u]:
                parent[v] = u
                stack[top] = v
                top += 1

    var down_sum = InlineArray[Int64, 32]()
    var up_sum = InlineArray[Int64, 32]()
    var answer = InlineArray[Int64, 32]()
    var down_count = InlineArray[Int, 32]()
    var up_count = InlineArray[Int, 32]()
    var position = order_count
    while position > 0:
        position -= 1
        let u = order[position]
        down_sum[u] = vertex_value[u]
        down_count[u] = 1
        for v in range(n):
            let cell = u * TPC_MAX_N + v
            if adjacent[cell] and parent[v] == u:
                let contribution = (multiplier[cell] * down_sum[v]
                    + addend[cell] * Int64(down_count[v])) % TPC_MOD
                down_sum[u] = (down_sum[u] + contribution) % TPC_MOD
                down_count[u] += down_count[v]

    for position in range(order_count):
        let u = order[position]
        var total_sum = vertex_value[u]
        var total_count = 1
        if parent[u] >= 0:
            total_sum = (total_sum + up_sum[u]) % TPC_MOD
            total_count += up_count[u]
        for v in range(n):
            let cell = u * TPC_MAX_N + v
            if adjacent[cell] and parent[v] == u:
                total_sum = (total_sum + multiplier[cell] * down_sum[v]
                    + addend[cell] * Int64(down_count[v])) % TPC_MOD
                total_count += down_count[v]
        answer[u] = total_sum
        for v in range(n):
            let cell = u * TPC_MAX_N + v
            if adjacent[cell] and parent[v] == u:
                let contribution = (multiplier[cell] * down_sum[v]
                    + addend[cell] * Int64(down_count[v])) % TPC_MOD
                let outside_sum = (total_sum - contribution + TPC_MOD) % TPC_MOD
                let outside_count = total_count - down_count[v]
                up_sum[v] = (multiplier[cell] * outside_sum
                    + addend[cell] * Int64(outside_count)) % TPC_MOD
                up_count[v] = outside_count

    let required = 8 * n
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or Int(capacity) < required:
        return -2
    for vertex in range(n):
        let bits = bitcast[UInt64](answer[vertex])
        for byte in range(8):
            output[8 * vertex + byte] = UInt8((bits >> UInt(8 * byte)) & 255)
    return Int64(required)
