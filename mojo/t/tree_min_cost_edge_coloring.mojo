# Uncompiled matching-sensitivity tree edge-coloring draft.
from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

fn tec_assignment(d: Int, width: Int, cost: InlineArray[Int64, 256],
                  mut deletion: InlineArray[Int64, 16]) -> Int64:
    let inf: Int64 = 1000000000000000
    var row_dual = InlineArray[Int64, 17](fill=0)
    var col_dual = InlineArray[Int64, 17](fill=0)
    var owner = InlineArray[Int, 17](fill=0)
    for row in range(1, d+1):
        var previous = InlineArray[Int, 17](fill=0)
        var used = InlineArray[Bool, 17](fill=False)
        var slack = InlineArray[Int64, 17](fill=inf)
        owner[0] = row
        var col = 0
        while True:
            used[col] = True
            let active = owner[col]
            var step = inf
            var next_col = 0
            for candidate in range(1, width+1):
                if used[candidate]: continue
                let reduced = cost[16*(active-1)+candidate-1]-row_dual[active]-col_dual[candidate]
                if reduced < slack[candidate]:
                    slack[candidate] = reduced
                    previous[candidate] = col
                if slack[candidate] < step:
                    step = slack[candidate]
                    next_col = candidate
            if next_col == 0: return -1
            for candidate in range(width+1):
                if used[candidate]:
                    row_dual[owner[candidate]] += step
                    col_dual[candidate] -= step
                elif candidate != 0: slack[candidate] -= step
            col = next_col
            if owner[col] == 0: break
        while col != 0:
            let parent = previous[col]
            owner[col] = owner[parent]
            col = parent
    var base: Int64 = 0
    var free_col = width
    for col in range(width):
        if owner[col+1] != 0: base += cost[16*(owner[col+1]-1)+col]
        else: free_col = col
    if width == d: return base
    if free_col == width: return -1
    var distance = InlineArray[Int64, 16](fill=inf)
    distance[free_col] = 0
    for _ in range(d):
        var updated = distance
        for col in range(width):
            if owner[col+1] == 0: continue
            let row = owner[col+1]-1
            for dest in range(width):
                if distance[dest] != inf:
                    let value = cost[16*row+dest]-cost[16*row+col]+distance[dest]
                    if value < updated[col]: updated[col] = value
        distance = updated
    for col in range(width):
        if distance[col] == inf: return -1
        deletion[col] = base+distance[col]
    return base

@export("tree_min_cost_edge_coloring")
fn tree_min_cost_edge_coloring(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 82: return -1
    let nv = input[0]
    let kv = input[1]
    if nv < 1 or nv > 64 or kv < 1 or kv > 16: return -1
    let n = Int(nv)
    let k = Int(kv)
    if length != c_size_t(n+1+k): return -1
    var parents = InlineArray[Int, 64](fill=0)
    var degree = InlineArray[Int, 64](fill=0)
    var child_count = InlineArray[Int, 64](fill=0)
    for vertex in range(1, n):
        let raw = input[1+vertex]
        if raw < 0 or raw >= Int64(vertex): return -1
        parents[vertex] = Int(raw)
        degree[Int(raw)] += 1
        degree[vertex] += 1
    var prices = InlineArray[Int64, 16](fill=0)
    for color in range(k):
        let value = input[n+1+color]
        if value < 0 or value > 1000000: return -1
        prices[color] = value
    for vertex in range(n):
        if degree[vertex] > k: return -2
    for color in range(1, k):
        let value = prices[color]
        var j = color
        while j > 0 and prices[j-1] > value:
            prices[j] = prices[j-1]
            j -= 1
        prices[j] = value
    var children = InlineArray[Int, 1024](fill=0)
    for vertex in range(1, n):
        let parent = parents[vertex]
        children[16*parent+child_count[parent]] = vertex
        child_count[parent] += 1
    var tables = InlineArray[Int64, 1024](fill=0)
    var vertex = n-1
    while vertex >= 0:
        let d = child_count[vertex]
        if d != 0:
            let saturated = vertex == 0 and d == k
            let width = d if saturated else d+1
            var cost = InlineArray[Int64, 256](fill=0)
            var deletion = InlineArray[Int64, 16](fill=0)
            for row in range(d):
                let child = children[16*vertex+row]
                for col in range(width):
                    let index = col if col < child_count[child] else child_count[child]
                    cost[16*row+col] = prices[col]+tables[16*child+index]
            let base = tec_assignment(d, width, cost, deletion)
            if base < 0: return -1
            if saturated: tables[16*vertex] = base
            else:
                for col in range(width): tables[16*vertex+col] = deletion[col]
        vertex -= 1
    if child_count[0] == k: return tables[0]
    return tables[child_count[0]]
