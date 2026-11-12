from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

comptime MAX_N = 64
comptime MAX_Q = 128
comptime MAX_LEVEL = 8
comptime ROW_SIZE = MAX_N + 1
comptime ROW_COUNT = 2 * MAX_N
comptime MAX_INPUT_VALUES = 3 * MAX_N + 4 * MAX_Q + 1
comptime MAX_ABS_VALUE = 1_000_000

@fieldwise_init
struct Context(Copyable):
    var n: Int
    var degree: InlineArray[Int, MAX_N]
    var adjacent: InlineArray[Int, MAX_N * MAX_N]
    var removed: InlineArray[Bool, MAX_N]
    var parent: InlineArray[Int, MAX_N]
    var subtree_size: InlineArray[Int, MAX_N]
    var ancestor: InlineArray[Int, MAX_N * MAX_LEVEL]
    var distance: InlineArray[Int, MAX_N * MAX_LEVEL]
    var branch_for: InlineArray[Int, MAX_N * MAX_LEVEL]
    var path_length: InlineArray[Int, MAX_N]
    var branch_count: Int
    var fenwick: InlineArray[Int64, ROW_COUNT * ROW_SIZE]

fn collect_component(mut ctx: Context, start: Int,
                     mut order: InlineArray[Int, MAX_N]) -> Int:
    var stack = InlineArray[Int, MAX_N](fill=0)
    var top = 1
    var count = 0
    ctx.parent[start] = -1
    stack[0] = start
    while top > 0:
        top -= 1
        let u = stack[top]
        order[count] = u
        count += 1
        for i in range(ctx.degree[u]):
            let v = ctx.adjacent[u * MAX_N + i]
            if ctx.removed[v] or v == ctx.parent[u]:
                continue
            ctx.parent[v] = u
            stack[top] = v
            top += 1
    for index in range(count):
        let position = count - 1 - index
        let u = order[position]
        ctx.subtree_size[u] = 1
        for i in range(ctx.degree[u]):
            let v = ctx.adjacent[u * MAX_N + i]
            if not ctx.removed[v] and ctx.parent[v] == u:
                ctx.subtree_size[u] += ctx.subtree_size[v]
    return count

fn decompose(mut ctx: Context, start: Int, level: Int):
    var order = InlineArray[Int, MAX_N](fill=0)
    let count = collect_component(mut ctx, start, mut order)
    var center = start
    for index in range(count):
        let u = order[index]
        var largest = count - ctx.subtree_size[u]
        for i in range(ctx.degree[u]):
            let v = ctx.adjacent[u * MAX_N + i]
            if not ctx.removed[v] and ctx.parent[v] == u:
                largest = max(largest, ctx.subtree_size[v])
        if 2 * largest <= count:
            center = u
            break
    ctx.removed[center] = True
    let center_index = center * MAX_LEVEL + level
    ctx.ancestor[center_index] = center
    ctx.distance[center_index] = 0
    ctx.branch_for[center_index] = -1
    ctx.path_length[center] = level + 1
    for edge in range(ctx.degree[center]):
        let root = ctx.adjacent[center * MAX_N + edge]
        if ctx.removed[root]:
            continue
        let branch_id = ctx.branch_count
        ctx.branch_count += 1
        var nodes = InlineArray[Int, MAX_N](fill=0)
        var parents = InlineArray[Int, MAX_N](fill=0)
        var distances = InlineArray[Int, MAX_N](fill=0)
        var top = 1
        nodes[0] = root
        parents[0] = center
        distances[0] = 1
        while top > 0:
            top -= 1
            let u = nodes[top]
            let p = parents[top]
            let d = distances[top]
            let index = u * MAX_LEVEL + level
            ctx.ancestor[index] = center
            ctx.distance[index] = d
            ctx.branch_for[index] = branch_id
            ctx.path_length[u] = level + 1
            for i in range(ctx.degree[u]):
                let v = ctx.adjacent[u * MAX_N + i]
                if ctx.removed[v] or v == p:
                    continue
                nodes[top] = v
                parents[top] = u
                distances[top] = d + 1
                top += 1
        decompose(mut ctx, root, level + 1)

fn fenwick_add(tree: UnsafePointer[Int64, MutAnyOrigin], row: Int,
               position: Int, delta: Int64):
    var index = position + 1
    while index <= MAX_N:
        tree[row * ROW_SIZE + index] += delta
        index += index & (-index)

fn fenwick_prefix(tree: UnsafePointer[Int64, MutAnyOrigin], row: Int,
                  count: Int) -> Int64:
    var total: Int64 = 0
    var index = count
    while index > 0:
        total += tree[row * ROW_SIZE + index]
        index -= index & (-index)
    return total

fn row_range(tree: UnsafePointer[Int64, MutAnyOrigin], row: Int,
             left_value: Int, right_value: Int) -> Int64:
    let left = max(0, min(MAX_N, left_value))
    let right = max(0, min(MAX_N, right_value))
    if right <= left:
        return 0
    return fenwick_prefix(tree, row, right) - fenwick_prefix(tree, row, left)

fn store_i64_le(output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int,
                value: Int64):
    let bits = bitcast[UInt64](value)
    for byte in range(8):
        output[offset + byte] = UInt8((bits >> (8 * byte)) & 255)

@export("vertex_add_range_contour_sum_on_tree")
fn vertex_add_range_contour_sum_on_tree(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t,
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > c_size_t(MAX_INPUT_VALUES):
        return -1
    let n_value = input[0]
    let q_value = input[1]
    if n_value < 1 or n_value > MAX_N or q_value < 0 or q_value > MAX_Q:
        return -1
    let n = Int(n_value)
    let q = Int(q_value)
    if length < c_size_t(3 * n):
        return -1

    var ctx = Context(
        n,
        InlineArray[Int, MAX_N](fill=0),
        InlineArray[Int, MAX_N * MAX_N](fill=0),
        InlineArray[Bool, MAX_N](fill=False),
        InlineArray[Int, MAX_N](fill=-1),
        InlineArray[Int, MAX_N](fill=0),
        InlineArray[Int, MAX_N * MAX_LEVEL](fill=-1),
        InlineArray[Int, MAX_N * MAX_LEVEL](fill=0),
        InlineArray[Int, MAX_N * MAX_LEVEL](fill=-1),
        InlineArray[Int, MAX_N](fill=0),
        0,
        InlineArray[Int64, ROW_COUNT * ROW_SIZE](fill=0),
    )
    var values = InlineArray[Int64, MAX_N](fill=0)
    for v in range(n):
        values[v] = input[2 + v]
        if values[v] < -MAX_ABS_VALUE or values[v] > MAX_ABS_VALUE:
            return -1

    let edge_start = 2 + n
    for i in range(n - 1):
        let u_value = input[edge_start + 2 * i]
        let v_value = input[edge_start + 2 * i + 1]
        if u_value < 0 or u_value >= n_value or v_value < 0 or v_value >= n_value or u_value == v_value:
            return -1
        let u = Int(u_value)
        let v = Int(v_value)
        for j in range(ctx.degree[u]):
            if ctx.adjacent[u * MAX_N + j] == v:
                return -1
        ctx.adjacent[u * MAX_N + ctx.degree[u]] = v
        ctx.degree[u] += 1
        ctx.adjacent[v * MAX_N + ctx.degree[v]] = u
        ctx.degree[v] += 1

    var seen = InlineArray[Bool, MAX_N](fill=False)
    var stack = InlineArray[Int, MAX_N](fill=0)
    var top = 1
    var visited = 0
    stack[0] = 0
    seen[0] = True
    while top > 0:
        top -= 1
        let u = stack[top]
        visited += 1
        for i in range(ctx.degree[u]):
            let v = ctx.adjacent[u * MAX_N + i]
            if not seen[v]:
                seen[v] = True
                stack[top] = v
                top += 1
    if visited != n:
        return -1

    var kinds = InlineArray[Int, MAX_Q](fill=0)
    var vertices = InlineArray[Int, MAX_Q](fill=0)
    var first = InlineArray[Int64, MAX_Q](fill=0)
    var second = InlineArray[Int64, MAX_Q](fill=0)
    var query_count = 0
    var cursor = 3 * n
    for i in range(q):
        if cursor >= Int(length):
            return -1
        let kind = input[cursor]
        cursor += 1
        if kind == 0:
            if cursor + 2 > Int(length):
                return -1
            let p = input[cursor]
            let delta = input[cursor + 1]
            cursor += 2
            if p < 0 or p >= n_value or delta < -MAX_ABS_VALUE or delta > MAX_ABS_VALUE:
                return -1
            kinds[i] = 0
            vertices[i] = Int(p)
            first[i] = delta
        elif kind == 1:
            if cursor + 3 > Int(length):
                return -1
            let p = input[cursor]
            let left = input[cursor + 1]
            let right = input[cursor + 2]
            cursor += 3
            if p < 0 or p >= n_value or left < 0 or left >= right or right > n_value:
                return -1
            kinds[i] = 1
            vertices[i] = Int(p)
            first[i] = left
            second[i] = right
            query_count += 1
        else:
            return -1
    if cursor != Int(length):
        return -1

    decompose(mut ctx, 0, 0)
    for v in range(n):
        for d in range(ctx.path_length[v]):
            let index = v * MAX_LEVEL + d
            let center = ctx.ancestor[index]
            let branch_id = ctx.branch_for[index]
            fenwick_add(ctx.fenwick.unsafe_ptr(), center, ctx.distance[index], values[v])
            if branch_id >= 0:
                fenwick_add(ctx.fenwick.unsafe_ptr(), MAX_N + branch_id, ctx.distance[index], values[v])

    var answers = InlineArray[Int64, MAX_Q](fill=0)
    var answer_count = 0
    for i in range(q):
        let p = vertices[i]
        if kinds[i] == 0:
            for d in range(ctx.path_length[p]):
                let index = p * MAX_LEVEL + d
                let center = ctx.ancestor[index]
                let branch_id = ctx.branch_for[index]
                fenwick_add(ctx.fenwick.unsafe_ptr(), center, ctx.distance[index], first[i])
                if branch_id >= 0:
                    fenwick_add(ctx.fenwick.unsafe_ptr(), MAX_N + branch_id, ctx.distance[index], first[i])
        else:
            var total: Int64 = 0
            for d in range(ctx.path_length[p]):
                let index = p * MAX_LEVEL + d
                let center = ctx.ancestor[index]
                let branch_id = ctx.branch_for[index]
                let left = Int(first[i]) - ctx.distance[index]
                let right = Int(second[i]) - ctx.distance[index]
                total += row_range(ctx.fenwick.unsafe_ptr(), center, left, right)
                if branch_id >= 0:
                    total -= row_range(ctx.fenwick.unsafe_ptr(), MAX_N + branch_id, left, right)
            answers[answer_count] = total
            answer_count += 1

    let output_bytes = 8 * answer_count
    if output_bytes > 0 and (output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(output_bytes)):
        return -2
    for i in range(answer_count):
        store_i64_le(output, 8 * i, answers[i])
    return Int64(output_bytes)
