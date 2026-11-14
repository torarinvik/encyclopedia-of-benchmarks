# Independent bounded Tarjan–Vishkin profile; see package LICENSE.txt.
from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("gbbs_biconnectivity")
fn gbbs_biconnectivity(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                       output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 50: return -1
    let raw_n = input[0]
    let raw_m = input[1]
    if raw_n < 1 or raw_n > 12 or raw_m < 0 or raw_m > 24: return -1
    let n = Int(raw_n)
    let m = Int(raw_m)
    if Int(length) != 2 + 2 * m: return -1
    var adjacent = InlineArray[Bool, 144](fill=False)
    for edge in range(m):
        let a = input[2 + 2 * edge]
        let b = input[3 + 2 * edge]
        if a < 0 or b <= a or b >= raw_n: return -1
        let u = Int(a)
        let v = Int(b)
        if adjacent[u * 12 + v]: return -1
        adjacent[u * 12 + v] = True
        adjacent[v * 12 + u] = True
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(m): return -2
    var parent = InlineArray[Int, 12](fill=0)
    var seen = InlineArray[Bool, 12](fill=False)
    var frontier = InlineArray[Int, 12](fill=0)
    for i in range(n): parent[i] = i
    for root in range(n):
        if seen[root]: continue
        seen[root] = True
        frontier[0] = root
        var count = 1
        while count > 0:
            var candidate = InlineArray[Int, 12](fill=12)
            for index in range(count):
                let u = frontier[index]
                for v in range(n):
                    if adjacent[u * 12 + v] and not seen[v] and u < candidate[v]: candidate[v] = u
            count = 0
            for v in range(n):
                if candidate[v] < 12:
                    parent[v] = candidate[v]
                    seen[v] = True
                    frontier[count] = v
                    count += 1
    var preorder = InlineArray[Int, 12](fill=0)
    var order = InlineArray[Int, 12](fill=0)
    var size = InlineArray[Int, 12](fill=1)
    var stack = InlineArray[Int, 12](fill=0)
    var used = 0
    for root in range(n):
        if parent[root] != root: continue
        let start = used
        var number = 0
        var top = 1
        stack[0] = root
        while top > 0:
            top -= 1
            let u = stack[top]
            preorder[u] = number
            number += 1
            order[used] = u
            used += 1
            var child = n - 1
            while child >= 0:
                if child != u and parent[child] == u:
                    stack[top] = child
                    top += 1
                child -= 1
        var index = used
        while index > start:
            index -= 1
            let u = order[index]
            if parent[u] != u: size[parent[u]] += size[u]
    var low = preorder
    var high = InlineArray[Int, 12](fill=0)
    for u in range(n): high[u] = preorder[u] + size[u] - 1
    for edge in range(m):
        let u = Int(input[2 + 2 * edge])
        let v = Int(input[3 + 2 * edge])
        if parent[u] != v and parent[v] != u:
            if preorder[u] < low[v]: low[v] = preorder[u]
            elif preorder[u] > high[v]: high[v] = preorder[u]
            if preorder[v] < low[u]: low[u] = preorder[v]
            elif preorder[v] > high[u]: high[u] = preorder[v]
    var index = n
    while index > 0:
        index -= 1
        let u = order[index]
        if parent[u] != u:
            let p = parent[u]
            low[p] = min(low[p], low[u])
            high[p] = max(high[p], high[u])
    var critical = InlineArray[Bool, 12](fill=False)
    for u in range(n):
        let p = parent[u]
        critical[u] = u != p and low[u] >= preorder[p] and high[u] < preorder[p] + size[p]
    var component = InlineArray[Int, 12](fill=12)
    var queue = InlineArray[Int, 12](fill=0)
    for root in range(n):
        if component[root] != 12: continue
        component[root] = root
        queue[0] = root
        var head = 0
        var tail = 1
        while head < tail:
            let u = queue[head]
            head += 1
            for v in range(n):
                let cut = (parent[u] == v and critical[u]) or (parent[v] == u and critical[v])
                if adjacent[u * 12 + v] and not cut and component[v] == 12:
                    component[v] = root
                    queue[tail] = v
                    tail += 1
    var labels = InlineArray[Int, 24](fill=0)
    for edge in range(m):
        let u = Int(input[2 + 2 * edge])
        let v = Int(input[3 + 2 * edge])
        labels[edge] = component[v] if parent[v] == u and critical[v] else component[u]
    for edge in range(m):
        var first = m
        for other in range(m):
            if labels[other] == labels[edge]: first = min(first, other)
        output[edge] = UInt8(first)
    return Int64(m)
