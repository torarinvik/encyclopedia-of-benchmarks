from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn srm_root(inout parent: InlineArray[Int, 36], start: Int) -> Int:
    var x = start
    while parent[x] != x:
        parent[x] = parent[parent[x]]
        x = parent[x]
    return x

@export("statistical_region_merging_table")
fn statistical_region_merging_table(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 4 or length > 74: return -1
    if input[0] < 1 or input[0] > 6 or input[1] < 1 or input[1] > 6: return -1
    let width = Int(input[1])
    let n = Int(input[0]) * width
    if length != c_size_t(2 + 2*n): return -1
    for i in range(n):
        if input[2+i] < 0 or input[2+i] > 65535 or input[2+n+i] < 0 or input[2+n+i] > 255: return -1
    var parent = InlineArray[Int, 36](fill=0)
    var sizes = InlineArray[Int, 36](fill=1)
    var minimum = InlineArray[Int, 36](fill=0)
    var sums = InlineArray[Int64, 36](fill=0)
    for i in range(n):
        parent[i] = i
        minimum[i] = i
        sums[i] = input[2+n+i]
    for difference in range(256):
        for p in range(n):
            var neighbors = InlineArray[Int, 2](fill=0)
            var count = 0
            if p % width + 1 < width:
                neighbors[count] = p+1
                count += 1
            if p + width < n:
                neighbors[count] = p+width
                count += 1
            for k in range(count):
                let q = neighbors[k]
                var d = input[2+n+p] - input[2+n+q]
                if d < 0: d = -d
                if d != Int64(difference): continue
                var a = srm_root(parent, p)
                var b = srm_root(parent, q)
                if a == b: continue
                let na = Int64(sizes[a])
                let nb = Int64(sizes[b])
                let delta = sums[a]*nb - sums[b]*na
                let bound = input[1+sizes[a]] + input[1+sizes[b]]
                if delta*delta > bound*na*na*nb*nb: continue
                if sizes[a] < sizes[b]:
                    let t = a
                    a = b
                    b = t
                parent[b] = a
                sizes[a] += sizes[b]
                sums[a] += sums[b]
                if minimum[b] < minimum[a]: minimum[a] = minimum[b]
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(n): return -2
    for i in range(n): output[i] = UInt8(minimum[srm_root(parent, i)])
    return Int64(n)
