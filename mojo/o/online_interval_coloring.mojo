# Bounded level-based online coloring of closed intervals.
from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("online_interval_coloring")
fn online_interval_coloring(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                            output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > 129: return -1
    let nv = input[0]
    if nv < 0 or nv > 64 or length != c_size_t(1+2*nv): return -1
    let n = Int(nv)
    var left = List[Int64](capacity=n)
    var right = List[Int64](capacity=n)
    var levels = List[Int](capacity=n)
    var local = List[Int](capacity=n)
    var colors = List[Int64](capacity=n)
    for i in range(n):
        let a = input[1+2*i]
        let b = input[2+2*i]
        if a < -1000 or a > 1000 or b < -1000 or b > 1000 or a > b: return -1
        left.append(a); right.append(b); levels.append(0); local.append(0)
    let bytes = 8*n
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes): return -2
    for i in range(n):
        var level = 1
        while True:
            var fits = True
            for anchor in range(i+1):
                let point = left[anchor]
                var overlap = 0
                for j in range(i+1):
                    if (j == i or levels[j] <= level) and left[j] <= point and point <= right[j]: overlap += 1
                if overlap > level:
                    fits = False
                    break
            if fits: break
            level += 1
            if level > i+1: return -1
        levels[i] = level
        var used = 0
        for j in range(i):
            if levels[j] == level and left[j] <= right[i] and left[i] <= right[j]: used |= 1 << local[j]
        var color = 0
        while color < 3 and (used & (1 << color)) != 0: color += 1
        if color == 3: return -1
        local[i] = color
        colors.append(Int64(3*(level-1)+color))
    for i in range(n):
        for byte in range(8): output[8*i+byte] = UInt8((colors[i] >> (8*byte)) & 255)
    return Int64(bytes)
