from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("treewidth_exact_elimination_order")
fn treewidth_exact_elimination_order(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
        output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 58: return -1
    let n0 = input[0]; let m0 = input[1]
    if n0 < 1 or n0 > 8 or m0 < 0 or m0 > 28: return -1
    let n = Int(n0); let m = Int(m0)
    if m > n * (n - 1) // 2 or length != c_size_t(2 + 2 * m): return -1
    var base = List[Bool](length=n * n, fill=False)
    for edge in range(m):
        let a0 = input[2 + 2 * edge]; let b0 = input[3 + 2 * edge]
        if a0 < 0 or a0 >= b0 or b0 >= n0: return -1
        let a = Int(a0); let b = Int(b0)
        if base[a * n + b]: return -1
        base[a * n + b] = True; base[b * n + a] = True
    var permutation = List[Int](); var best = List[Int](length=n, fill=0)
    for i in range(n): permutation.append(i)
    var best_width = n + 1
    while True:
        var adjacent = List[Bool](length=n * n, fill=False)
        for i in range(n * n): adjacent[i] = base[i]
        var active = List[Bool](length=n, fill=True)
        var width = 0
        for step in range(n):
            let vertex = permutation[step]
            var neighbors = List[Int]()
            for other in range(n):
                if active[other] and adjacent[vertex * n + other]: neighbors.append(other)
            if len(neighbors) > width: width = len(neighbors)
            for i in range(len(neighbors)):
                for j in range(i + 1, len(neighbors)):
                    let a = neighbors[i]; let b = neighbors[j]
                    adjacent[a * n + b] = True; adjacent[b * n + a] = True
            active[vertex] = False
        if width < best_width:
            best_width = width
            for i in range(n): best[i] = permutation[i]
        var pivot = n - 2
        while pivot >= 0 and permutation[pivot] >= permutation[pivot + 1]: pivot -= 1
        if pivot < 0: break
        var successor = n - 1
        while permutation[successor] <= permutation[pivot]: successor -= 1
        let saved = permutation[pivot]
        permutation[pivot] = permutation[successor]; permutation[successor] = saved
        var left = pivot + 1; var right = n - 1
        while left < right:
            let value = permutation[left]
            permutation[left] = permutation[right]; permutation[right] = value
            left += 1; right -= 1
    let bytes = 8 * (n + 1)
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes): return -2
    for i in range(n + 1):
        var value = Int64(best_width)
        if i > 0: value = Int64(best[i - 1])
        for byte in range(8): output[8 * i + byte] = UInt8((value >> (8 * byte)) & 255)
    return Int64(bytes)
