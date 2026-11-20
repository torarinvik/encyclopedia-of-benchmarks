from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

comptime MAX_N = 64
comptime MAX_COLORS = 256
comptime MAX_INPUT = 130

fn tds_add_interval(begin: Int, count: Int, delta: Int,
                    order: InlineArray[Int, MAX_N], colors: InlineArray[Int, MAX_N],
                    inout frequency: InlineArray[Int, MAX_COLORS],
                    inout distinct: Int):
    for offset in range(count):
        let color = colors[order[begin + offset]]
        if delta > 0:
            if frequency[color] == 0:
                distinct += 1
            frequency[color] += 1
        else:
            frequency[color] -= 1
            if frequency[color] == 0:
                distinct -= 1

fn tds_solve(n: Int, parent: InlineArray[Int, MAX_N],
             first_child: InlineArray[Int, MAX_N], next_sibling: InlineArray[Int, MAX_N],
             colors: InlineArray[Int, MAX_N],
             inout order: InlineArray[Int, MAX_N], inout tin: InlineArray[Int, MAX_N],
             inout subtree_size: InlineArray[Int, MAX_N], inout heavy: InlineArray[Int, MAX_N],
             inout frequency: InlineArray[Int, MAX_COLORS],
             inout answer: InlineArray[Int, MAX_N]):
    var stack_next = InlineArray[Int, MAX_N](fill=-1)
    var depth = 1
    var timer = 1
    order[0] = 0
    tin[0] = 0
    stack_next[0] = first_child[0]
    while depth > 0:
        let frame = depth - 1
        let child = stack_next[frame]
        if child >= 0:
            stack_next[frame] = next_sibling[child]
            tin[child] = timer
            order[timer] = child
            timer += 1
            stack_next[depth] = first_child[child]
            depth += 1
        else:
            depth -= 1

    for vertex in range(n):
        subtree_size[vertex] = 1
        heavy[vertex] = -1
    for reverse in range(n - 1):
        let position = n - 1 - reverse
        let vertex = order[position]
        let p = parent[vertex]
        subtree_size[p] += subtree_size[vertex]
        let old_heavy = heavy[p]
        if old_heavy < 0 or subtree_size[vertex] > subtree_size[old_heavy]:
            heavy[p] = vertex

    var frame_vertex = InlineArray[Int, MAX_N](fill=0)
    var frame_keep = InlineArray[Bool, MAX_N](fill=False)
    var frame_stage = InlineArray[Int, MAX_N](fill=0)
    var frame_child = InlineArray[Int, MAX_N](fill=-1)
    var frame_count = 1
    frame_vertex[0] = 0
    frame_keep[0] = False
    frame_stage[0] = 0
    frame_child[0] = first_child[0]
    var distinct = 0
    while frame_count > 0:
        let frame = frame_count - 1
        let vertex = frame_vertex[frame]
        if frame_stage[frame] == 0:
            var child = frame_child[frame]
            while child >= 0 and child == heavy[vertex]:
                child = next_sibling[child]
            if child >= 0:
                frame_child[frame] = next_sibling[child]
                frame_vertex[frame_count] = child
                frame_keep[frame_count] = False
                frame_stage[frame_count] = 0
                frame_child[frame_count] = first_child[child]
                frame_count += 1
            else:
                frame_stage[frame] = 1
        elif frame_stage[frame] == 1:
            frame_stage[frame] = 2
            let child = heavy[vertex]
            if child >= 0:
                frame_vertex[frame_count] = child
                frame_keep[frame_count] = True
                frame_stage[frame_count] = 0
                frame_child[frame_count] = first_child[child]
                frame_count += 1
        else:
            var child = first_child[vertex]
            while child >= 0:
                if child != heavy[vertex]:
                    tds_add_interval(tin[child], subtree_size[child], 1, order, colors,
                                     frequency, distinct)
                child = next_sibling[child]
            let color = colors[vertex]
            if frequency[color] == 0:
                distinct += 1
            frequency[color] += 1
            answer[vertex] = distinct
            if not frame_keep[frame]:
                tds_add_interval(tin[vertex], subtree_size[vertex], -1, order, colors,
                                 frequency, distinct)
            frame_count -= 1

fn tds_write_i64(output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int, value: Int64):
    let bits = bitcast[UInt64](value)
    for byte in range(8):
        output[offset + byte] = UInt8((bits >> (8 * byte)) & UInt64(255))

@export("tree_subtree_distinct_sack")
fn tree_subtree_distinct_sack(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                              output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > c_size_t(MAX_INPUT):
        return -1
    let n_value = input[0]
    if n_value < 1 or n_value > MAX_N or length != c_size_t(2 * n_value):
        return -1
    let n = Int(n_value)
    for vertex in range(1, n):
        if input[vertex] < 0 or input[vertex] >= Int64(vertex):
            return -1
    var colors = InlineArray[Int, MAX_N](fill=0)
    for vertex in range(n):
        let color = input[n + vertex]
        if color < 0 or color >= MAX_COLORS:
            return -1
        colors[vertex] = Int(color)
    let required = 8 * n
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(required):
        return -2

    var parent = InlineArray[Int, MAX_N](fill=0)
    var first_child = InlineArray[Int, MAX_N](fill=-1)
    var next_sibling = InlineArray[Int, MAX_N](fill=-1)
    for vertex in range(1, n):
        let p = Int(input[vertex])
        parent[vertex] = p
        next_sibling[vertex] = first_child[p]
        first_child[p] = vertex
    var order = InlineArray[Int, MAX_N](fill=0)
    var tin = InlineArray[Int, MAX_N](fill=0)
    var subtree_size = InlineArray[Int, MAX_N](fill=0)
    var heavy = InlineArray[Int, MAX_N](fill=-1)
    var frequency = InlineArray[Int, MAX_COLORS](fill=0)
    var answer = InlineArray[Int, MAX_N](fill=0)
    tds_solve(n, parent, first_child, next_sibling, colors, order, tin,
              subtree_size, heavy, frequency, answer)
    for vertex in range(n):
        tds_write_i64(output, 8 * vertex, Int64(answer[vertex]))
    return Int64(required)
