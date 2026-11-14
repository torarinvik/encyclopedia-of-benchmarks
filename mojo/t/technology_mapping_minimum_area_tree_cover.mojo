from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("technology_mapping_minimum_area_tree_cover")
fn technology_mapping_minimum_area_tree_cover(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
        output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 9 or length > 99: return -1
    let nv = input[0]
    if nv < 1 or nv > 31: return -1
    let n = Int(nv)
    if length != c_size_t(6+3*n): return -1
    var costs = List[Int64](capacity=5)
    for i in range(5):
        let cost = input[1+i]
        if cost != -1 and (cost < 1 or cost > 1000000): return -1
        costs.append(cost)
    var kinds = List[Int](capacity=n)
    var left = List[Int](capacity=n)
    var right = List[Int](capacity=n)
    var parents = List[Int](capacity=n)
    for _ in range(n): parents.append(0)
    for i in range(n):
        let k = input[6+3*i]; let l = input[7+3*i]; let r = input[8+3*i]
        if k < 0 or k > 2: return -1
        if k == 0:
            if l != -1 or r != -1: return -1
        elif k == 1:
            if l <= Int64(i) or l >= nv or r != -1: return -1
            parents[Int(l)] += 1
        else:
            if l <= Int64(i) or l >= nv or r <= Int64(i) or r >= nv or l == r: return -1
            parents[Int(l)] += 1
            parents[Int(r)] += 1
        kinds.append(Int(k)); left.append(Int(l)); right.append(Int(r))
    for i in range(1,n):
        if parents[i] != 1: return -1
    let infinity = Int64(1) << 60
    var best = List[Int64](capacity=n)
    var choice = List[Int](capacity=n)
    for _ in range(n): best.append(infinity); choice.append(-1)
    for reverse_i in range(n):
        let i = n-1-reverse_i
        if kinds[i] == 0:
            best[i] = 0
            continue
        let l = left[i]
        if kinds[i] == 1:
            if costs[0] >= 0 and best[l] < infinity:
                best[i] = costs[0]+best[l]
                choice[i] = 0
            continue
        let r = right[i]
        # Try IDs in ascending order, preserving the first on equal cost.
        for p in range(1,5):
            if costs[p] < 0: continue
            var a = l
            var b = r
            if p == 2 or p == 4:
                if kinds[l] != 1: continue
                a = left[l]
            if p == 3 or p == 4:
                if kinds[r] != 1: continue
                b = left[r]
            if best[a] == infinity or best[b] == infinity: continue
            let candidate = costs[p]+best[a]+best[b]
            if candidate < best[i]:
                best[i] = candidate
                choice[i] = p
    if best[0] == infinity: return -1
    var mapping = List[Int64](capacity=n)
    for i in range(n):
        if kinds[i] == 0: mapping.append(-1)
        else: mapping.append(-3)
    var stack = List[Int](capacity=n)
    stack.append(0)
    while len(stack) > 0:
        let node = stack.pop()
        if kinds[node] == 0: continue
        let p = choice[node]
        mapping[node] = Int64(p)
        let l = left[node]
        if p == 0:
            stack.append(l)
        else:
            let r = right[node]
            var a = l
            var b = r
            if p == 2 or p == 4:
                mapping[l] = -2
                a = left[l]
            if p == 3 or p == 4:
                mapping[r] = -2
                b = left[r]
            stack.append(a)
            stack.append(b)
    let bytes = 8*(n+1)
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes): return -2
    for i in range(n+1):
        var value = best[0]
        if i > 0: value = mapping[i-1]
        for j in range(8): output[8*i+j] = UInt8((value >> (8*j)) & 255)
    return Int64(bytes)
