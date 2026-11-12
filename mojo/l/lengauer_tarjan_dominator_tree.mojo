from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

comptime MAX_V = 63
comptime MAX_E = 2047
comptime MAX_INPUT = 4097

fn lt_evaluate(vertex: Int, inout ancestor: InlineArray[Int32, MAX_V + 1],
    inout label: InlineArray[Int32, MAX_V + 1],
    semi: InlineArray[Int32, MAX_V + 1],
    inout path: InlineArray[Int32, MAX_V + 1]) -> Int:
    if ancestor[vertex] == 0: return vertex
    var used = 0
    var current = vertex
    while ancestor[Int(ancestor[current])] != 0:
        path[used] = Int32(current)
        used += 1
        current = Int(ancestor[current])
    while used > 0:
        used -= 1
        current = Int(path[used])
        let parent = Int(ancestor[current])
        if semi[Int(label[parent])] < semi[Int(label[current])]: label[current] = label[parent]
        ancestor[current] = ancestor[parent]
    return Int(label[vertex])

@export("lengauer_tarjan_dominator_tree")
fn lengauer_tarjan_dominator_tree(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t,
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3 or length > c_size_t(MAX_INPUT):
        return -1
    let nv = input[0]
    let root_value = input[1]
    let me = input[2]
    if nv < 1 or nv > MAX_V or root_value < 0 or root_value >= nv or me < 0 or me > MAX_E:
        return -1
    let n = Int(nv)
    let root = Int(root_value)
    let m = Int(me)
    if length != c_size_t(3 + 2 * m): return -1

    var outmask = InlineArray[UInt64, MAX_V](fill=0)
    var out_head = InlineArray[Int32, MAX_V](fill=-1)
    var edge_source = InlineArray[Int32, MAX_E](fill=0)
    var edge_target = InlineArray[Int32, MAX_E](fill=0)
    var out_next = InlineArray[Int32, MAX_E](fill=-1)
    var pred_head = InlineArray[Int32, MAX_V + 1](fill=-1)
    var pred_next = InlineArray[Int32, MAX_E](fill=-1)
    var dfs_number = InlineArray[Int32, MAX_V](fill=0)
    var vertex_at = InlineArray[Int32, MAX_V + 1](fill=0)
    var parent = InlineArray[Int32, MAX_V + 1](fill=0)
    var semi = InlineArray[Int32, MAX_V + 1](fill=0)
    var ancestor = InlineArray[Int32, MAX_V + 1](fill=0)
    var label = InlineArray[Int32, MAX_V + 1](fill=0)
    var immediate = InlineArray[Int32, MAX_V + 1](fill=0)
    var bucket_head = InlineArray[Int32, MAX_V + 1](fill=-1)
    var bucket_next = InlineArray[Int32, MAX_V + 1](fill=0)
    var node_stack = InlineArray[Int32, MAX_V](fill=0)
    var edge_stack = InlineArray[Int32, MAX_V](fill=-1)
    var eval_path = InlineArray[Int32, MAX_V + 1](fill=0)
    var staged = InlineArray[UInt8, MAX_V](fill=0)

    var edge_count = 0
    for i in range(m):
        let sv = input[3 + 2 * i]
        let tv = input[4 + 2 * i]
        if sv < 0 or sv >= nv or tv < 0 or tv >= nv: return -1
        let source = Int(sv)
        let target = Int(tv)
        let bit = UInt64(1) << target
        if outmask[source] & bit == 0:
            outmask[source] = outmask[source] | bit
            edge_source[edge_count] = Int32(source)
            edge_target[edge_count] = Int32(target)
            out_next[edge_count] = out_head[source]
            out_head[source] = Int32(edge_count)
            edge_count += 1

    var dfs_count = 1
    var top = 1
    dfs_number[root] = 1
    vertex_at[1] = Int32(root)
    node_stack[0] = Int32(root)
    edge_stack[0] = out_head[root]
    while top > 0:
        let frame = top - 1
        let current = Int(node_stack[frame])
        let edge = Int(edge_stack[frame])
        if edge == -1:
            top -= 1
            continue
        edge_stack[frame] = out_next[edge]
        let target = Int(edge_target[edge])
        if dfs_number[target] == 0:
            dfs_count += 1
            dfs_number[target] = Int32(dfs_count)
            vertex_at[dfs_count] = Int32(target)
            parent[dfs_count] = dfs_number[current]
            node_stack[top] = Int32(target)
            edge_stack[top] = out_head[target]
            top += 1

    for edge in range(edge_count):
        let source_number = Int(dfs_number[Int(edge_source[edge])])
        let target_number = Int(dfs_number[Int(edge_target[edge])])
        if source_number != 0 and target_number != 0:
            pred_next[edge] = pred_head[target_number]
            pred_head[target_number] = Int32(edge)
    for vertex in range(1, dfs_count + 1):
        semi[vertex] = Int32(vertex)
        label[vertex] = Int32(vertex)

    for w in range(dfs_count, 1, -1):
        var edge = Int(pred_head[w])
        while edge != -1:
            let predecessor = Int(dfs_number[Int(edge_source[edge])])
            let representative = lt_evaluate(predecessor, ancestor, label, semi, eval_path)
            if semi[representative] < semi[w]: semi[w] = semi[representative]
            edge = Int(pred_next[edge])
        bucket_next[w] = bucket_head[Int(semi[w])]
        bucket_head[Int(semi[w])] = Int32(w)
        ancestor[w] = parent[w]
        let owner = Int(parent[w])
        var member = Int(bucket_head[owner])
        bucket_head[owner] = -1
        while member != -1:
            let next = Int(bucket_next[member])
            let representative = lt_evaluate(member, ancestor, label, semi, eval_path)
            if semi[representative] < semi[member]: immediate[member] = Int32(representative)
            else: immediate[member] = Int32(owner)
            member = next
    for w in range(2, dfs_count + 1):
        if immediate[w] != semi[w]: immediate[w] = immediate[Int(immediate[w])]
    immediate[1] = 1

    for vertex in range(n):
        let number = Int(dfs_number[vertex])
        if number == 0: staged[vertex] = 255
        else: staged[vertex] = UInt8(vertex_at[Int(immediate[number])])
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(n): return -2
    for vertex in range(n): output[vertex] = staged[vertex]
    return Int64(n)
