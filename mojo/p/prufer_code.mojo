from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("prufer_code")
fn prufer_code(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 129: return -1
    let mode = input[0]
    if (mode != 0 and mode != 1) or input[1] < 1 or input[1] > 64: return -1
    let n = Int(input[1])
    var words = InlineArray[Int64, 127](fill=0)
    var word_count = 0
    if mode == 0:
        if length != c_size_t(2*n): return -1
        var adjacency = InlineArray[UInt8, 4096](fill=0)
        var degree = InlineArray[Int, 64](fill=0)
        for i in range(n-1):
            let ru = input[2+2*i]
            let rv = input[3+2*i]
            if ru < 0 or rv < 0 or ru >= Int64(n) or rv >= Int64(n) or ru == rv: return -1
            let u = Int(ru)
            let v = Int(rv)
            if adjacency[64*u+v] != 0: return -1
            adjacency[64*u+v] = 1
            adjacency[64*v+u] = 1
            degree[u] += 1
            degree[v] += 1
        var visited = InlineArray[Bool, 64](fill=False)
        var queue = InlineArray[Int, 64](fill=0)
        visited[0] = True
        var head = 0
        var tail = 1
        while head < tail:
            let u = queue[head]
            head += 1
            for v in range(n):
                if adjacency[64*u+v] != 0 and not visited[v]:
                    visited[v] = True
                    queue[tail] = v
                    tail += 1
        if tail != n: return -1
        for step in range(max(0,n-2)):
            var leaf = -1
            for v in range(n):
                if degree[v] == 1: leaf = v
            if leaf < 0: return -1
            var neighbor = -1
            for v in range(n):
                if adjacency[64*leaf+v] != 0: neighbor = v
            if neighbor < 0: return -1
            words[step] = Int64(neighbor)
            adjacency[64*leaf+neighbor] = 0
            adjacency[64*neighbor+leaf] = 0
            degree[leaf] = 0
            degree[neighbor] -= 1
        word_count = max(0,n-2)
    else:
        if n < 2 or length != c_size_t(n): return -1
        var remaining = InlineArray[Int, 64](fill=0)
        var active = InlineArray[Bool, 64](fill=False)
        for v in range(n): active[v] = True
        for i in range(n-2):
            if input[2+i] < 0 or input[2+i] >= Int64(n): return -1
            remaining[Int(input[2+i])] += 1
        var edge_u = InlineArray[Int, 63](fill=0)
        var edge_v = InlineArray[Int, 63](fill=0)
        for i in range(n-1):
            var leaf = -1
            for v in range(n):
                if active[v] and remaining[v] == 0: leaf = v
            if leaf < 0: return -1
            active[leaf] = False
            var neighbor = -1
            if i < n-2:
                neighbor = Int(input[2+i])
                remaining[neighbor] -= 1
            else:
                for v in range(n):
                    if active[v]: neighbor = v
            if neighbor < 0: return -1
            edge_u[i] = min(leaf,neighbor)
            edge_v[i] = max(leaf,neighbor)
        for i in range(1,n-1):
            let u = edge_u[i]
            let v = edge_v[i]
            var j = i
            while j > 0 and (edge_u[j-1] > u or (edge_u[j-1] == u and edge_v[j-1] > v)):
                edge_u[j] = edge_u[j-1]
                edge_v[j] = edge_v[j-1]
                j -= 1
            edge_u[j] = u
            edge_v[j] = v
        words[0] = Int64(n-1)
        for i in range(n-1):
            words[1+2*i] = Int64(edge_u[i])
            words[2+2*i] = Int64(edge_v[i])
        word_count = 1+2*(n-1)
    let bytes = 8*word_count
    if bytes == 0: return 0
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes): return -2
    var staged = InlineArray[UInt8, 1016](fill=0)
    for i in range(word_count):
        let bits = UInt64(words[i])
        for b in range(8): staged[8*i+b] = UInt8((bits >> UInt(8*b)) & 255)
    for i in range(bytes): output[i] = staged[i]
    return Int64(bytes)
