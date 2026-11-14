from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("zdd_family_count")
fn zdd_family_count(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
        output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 34: return -1
    let nv = input[0]; let mv = input[1]
    if nv < 1 or nv > 6 or mv < 0 or mv > 32 or length != c_size_t(2+Int(mv)): return -1
    let n = Int(nv); let domain = 1 << n
    var ids = List[Int](capacity=domain)
    var next = List[Int](capacity=domain)
    for _ in range(domain): ids.append(0); next.append(0)
    for i in range(Int(mv)):
        let mask = input[2+i]
        if mask < 0 or mask >= Int64(domain): return -1
        if ids[Int(mask)] != 0: return -1
        ids[Int(mask)] = 1
    var vars = List[Int](capacity=63)
    var lows = List[Int](capacity=63)
    var highs = List[Int](capacity=63)
    var counts = List[Int64](capacity=65)
    counts.append(0); counts.append(1)
    var current = domain
    for variable in range(n):
        let next_count = current//2
        for p in range(next_count):
            let low = ids[2*p]; let high = ids[2*p+1]
            if high == 0:
                next[p] = low
                continue
            var found = -1
            var j = len(vars)
            while j > 0:
                j -= 1
                if vars[j] != variable: break
                if lows[j] == low and highs[j] == high:
                    found = j
                    break
            if found < 0:
                found = len(vars)
                vars.append(variable); lows.append(low); highs.append(high)
                counts.append(counts[low]+counts[high])
            next[p] = 2+found
        for p in range(next_count): ids[p] = next[p]
        current = next_count
    let nodes = len(vars)
    let words = 3+3*nodes
    let bytes = 8*words
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes): return -2
    for i in range(words):
        var value = Int64(0)
        if i == 0: value = Int64(ids[0])
        elif i == 1: value = Int64(nodes)
        elif i == 2: value = counts[ids[0]]
        else:
            let index = (i-3)//3
            let field = (i-3)%3
            if field == 0: value = Int64(vars[index])
            elif field == 1: value = Int64(lows[index])
            else: value = Int64(highs[index])
        for j in range(8): output[8*i+j] = UInt8((value >> (8*j)) & 255)
    return Int64(bytes)
