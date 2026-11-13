from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("st_numbering")
fn st_numbering(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 4 or length > 60: return -1
    let n64 = input[0]
    let m64 = input[1]
    let s64 = input[2]
    let t64 = input[3]
    if n64 < 2 or n64 > 8 or m64 < 0 or m64 > 28 or s64 < 0 or s64 >= n64 or t64 < 0 or t64 >= n64 or s64 == t64: return -1
    let n = Int(n64)
    let m = Int(m64)
    let s = Int(s64)
    let t = Int(t64)
    if length != c_size_t(4 + 2 * m): return -1
    var eu = InlineArray[Int, 28](fill=0)
    var ev = InlineArray[Int, 28](fill=0)
    var adjacent = InlineArray[UInt64, 8](fill=0)
    var st_edge = -1
    for edge in range(m):
        let a = input[4 + 2 * edge]
        let b = input[5 + 2 * edge]
        if a < 0 or a >= n64 or b < 0 or b >= n64 or a == b: return -1
        let u = Int(a)
        let v = Int(b)
        if adjacent[u] & (UInt64(1) << UInt(v)) != 0: return -1
        adjacent[u] |= UInt64(1) << UInt(v)
        adjacent[v] |= UInt64(1) << UInt(u)
        eu[edge] = u
        ev[edge] = v
        if (u == s and v == t) or (u == t and v == s): st_edge = edge
    if st_edge < 0: return -1
    var head = InlineArray[Int, 8](fill=-1)
    var arc_to = InlineArray[Int, 56](fill=0)
    var arc_next = InlineArray[Int, 56](fill=-1)
    var arcs = 0
    for edge in range(m):
        if edge == st_edge: continue
        let u = eu[edge]
        let v = ev[edge]
        arc_to[arcs] = v
        arc_next[arcs] = head[u]
        head[u] = arcs
        arcs += 1
        arc_to[arcs] = u
        arc_next[arcs] = head[v]
        head[v] = arcs
        arcs += 1
    arc_to[arcs] = t
    arc_next[arcs] = head[s]
    head[s] = arcs
    arcs += 1
    arc_to[arcs] = s
    arc_next[arcs] = head[t]
    head[t] = arcs
    var parent = InlineArray[Int, 8](fill=-1)
    var discovery = InlineArray[Int, 8](fill=0)
    var low = InlineArray[Int, 8](fill=0)
    var children = InlineArray[Int, 8](fill=0)
    var next_arc = InlineArray[Int, 8](fill=-1)
    var preorder = InlineArray[Int, 8](fill=0)
    var stack = InlineArray[Int, 8](fill=0)
    for v in range(n): low[v] = v
    discovery[s] = 1
    preorder[0] = s
    next_arc[s] = head[s]
    stack[0] = s
    var top = 1
    var clock = 1
    var seen = 1
    while top > 0:
        let vertex = stack[top - 1]
        let arc = next_arc[vertex]
        if arc < 0:
            top -= 1
            let ancestor = parent[vertex]
            if ancestor >= 0 and discovery[low[vertex]] < discovery[low[ancestor]]: low[ancestor] = low[vertex]
            continue
        next_arc[vertex] = arc_next[arc]
        let neighbor = arc_to[arc]
        if neighbor == parent[vertex]: continue
        if discovery[neighbor] == 0:
            parent[neighbor] = vertex
            children[vertex] += 1
            clock += 1
            discovery[neighbor] = clock
            low[neighbor] = neighbor
            preorder[seen] = neighbor
            seen += 1
            next_arc[neighbor] = head[neighbor]
            stack[top] = neighbor
            top += 1
        elif discovery[neighbor] < discovery[vertex] and discovery[neighbor] < discovery[low[vertex]]:
            low[vertex] = neighbor
    if seen != n or children[s] != 1: return -1
    for vertex in range(n):
        if vertex == s: continue
        for child in range(n):
            if parent[child] == vertex and discovery[low[child]] >= discovery[vertex]: return -1
    var previous = InlineArray[Int, 8](fill=-1)
    var following = InlineArray[Int, 8](fill=-1)
    var sign = InlineArray[Int, 8](fill=0)
    sign[s] = -1
    following[s] = t
    previous[t] = s
    var list_head = s
    for order in range(2, n):
        let vertex = preorder[order]
        let ancestor = parent[vertex]
        if sign[low[vertex]] == -1:
            let left = previous[ancestor]
            previous[vertex] = left
            following[vertex] = ancestor
            previous[ancestor] = vertex
            if left >= 0: following[left] = vertex
            else: list_head = vertex
            sign[ancestor] = 1
        else:
            let right = following[ancestor]
            previous[vertex] = ancestor
            following[vertex] = right
            following[ancestor] = vertex
            if right >= 0: previous[right] = vertex
            sign[ancestor] = -1
    var rank = InlineArray[Int, 8](fill=0)
    var rank_value = 1
    var current = list_head
    while current >= 0 and rank_value <= n:
        rank[current] = rank_value
        rank_value += 1
        current = following[current]
    if rank_value != n + 1 or rank[s] != 1 or rank[t] != n: return -1
    for vertex in range(n):
        if vertex == s or vertex == t: continue
        var lower = False
        var higher = False
        var arc = head[vertex]
        while arc >= 0:
            let neighbor = arc_to[arc]
            if rank[neighbor] < rank[vertex]: lower = True
            if rank[neighbor] > rank[vertex]: higher = True
            arc = arc_next[arc]
        if not lower or not higher: return -1
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(n): return -2
    for vertex in range(n): output[vertex] = UInt8(rank[vertex])
    return Int64(n)
