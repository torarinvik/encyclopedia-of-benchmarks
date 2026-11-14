# Clean-room bounded median-cut palette construction; see package README.
from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("cbench_consumer_tiffmedian")
fn cbench_consumer_tiffmedian(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                              output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 5 or length > 50: return -1
    if input[0] < 1 or input[0] > 8 or input[1] < 1 or input[1] > 16: return -1
    let limit = Int(input[0]); let n = Int(input[1])
    if length != c_size_t(2+3*n): return -1
    var hist = InlineArray[Int, 32768](fill=0)
    var lo = InlineArray[Int, 24](fill=31)
    var hi = InlineArray[Int, 24](fill=0)
    var totals = InlineArray[Int, 8](fill=0)
    for i in range(n):
        for axis in range(3):
            if input[2+3*i+axis] < 0 or input[2+3*i+axis] > 255: return -1
        let r = Int(input[2+3*i] >> 3); let g = Int(input[3+3*i] >> 3); let b = Int(input[4+3*i] >> 3)
        hist[(r*32+g)*32+b] += 1
        for axis in range(3):
            var coordinate = r
            if axis == 1: coordinate = g
            elif axis == 2: coordinate = b
            if coordinate < lo[axis]: lo[axis] = coordinate
            if coordinate > hi[axis]: hi[axis] = coordinate
    totals[0] = n
    var box_count = 1
    while box_count < limit:
        var selected = -1; var largest = -1
        for i in range(box_count):
            if (lo[3*i] < hi[3*i] or lo[3*i+1] < hi[3*i+1] or lo[3*i+2] < hi[3*i+2]) and totals[i] > largest:
                selected = i; largest = totals[i]
        if selected < 0: break
        let rs = hi[3*selected]-lo[3*selected]
        let gs = hi[3*selected+1]-lo[3*selected+1]
        let bs = hi[3*selected+2]-lo[3*selected+2]
        var axis = 0
        if not (rs >= gs and rs >= bs):
            if gs >= bs: axis = 1
            else: axis = 2
        var along = InlineArray[Int, 32](fill=0)
        for r in range(lo[3*selected], hi[3*selected]+1):
            for g in range(lo[3*selected+1], hi[3*selected+1]+1):
                for b in range(lo[3*selected+2], hi[3*selected+2]+1):
                    var coordinate = r
                    if axis == 1: coordinate = g
                    elif axis == 2: coordinate = b
                    along[coordinate] += hist[(r*32+g)*32+b]
        let first = lo[3*selected+axis]; let last = hi[3*selected+axis]
        var split = first; var accumulated = 0
        while split <= last:
            accumulated += along[split]
            if accumulated >= totals[selected]//2: break
            split += 1
        if split == first: split += 1
        var lower_total = 0
        for i in range(first, split): lower_total += along[i]
        let upper_total = totals[selected]-lower_total
        var lower_lo = InlineArray[Int, 3](fill=0); var lower_hi = InlineArray[Int, 3](fill=0)
        var upper_lo = InlineArray[Int, 3](fill=0); var upper_hi = InlineArray[Int, 3](fill=0)
        for a in range(3):
            lower_lo[a] = lo[3*selected+a]; upper_lo[a] = lo[3*selected+a]
            lower_hi[a] = hi[3*selected+a]; upper_hi[a] = hi[3*selected+a]
        lower_hi[axis] = split-1; upper_lo[axis] = split
        # Contract each half to its occupied histogram bins.
        for half in range(2):
            var new_lo = InlineArray[Int, 3](fill=32); var new_hi = InlineArray[Int, 3](fill=-1)
            var rlo = lower_lo[0]; var rhi = lower_hi[0]
            var glo = lower_lo[1]; var ghi = lower_hi[1]
            var blo = lower_lo[2]; var bhi = lower_hi[2]
            if half == 1:
                rlo = upper_lo[0]; rhi = upper_hi[0]; glo = upper_lo[1]; ghi = upper_hi[1]; blo = upper_lo[2]; bhi = upper_hi[2]
            for r in range(rlo, rhi+1):
                for g in range(glo, ghi+1):
                    for b in range(blo, bhi+1):
                        if hist[(r*32+g)*32+b] == 0: continue
                        for a in range(3):
                            var coordinate = r
                            if a == 1: coordinate = g
                            elif a == 2: coordinate = b
                            if coordinate < new_lo[a]: new_lo[a] = coordinate
                            if coordinate > new_hi[a]: new_hi[a] = coordinate
            for a in range(3):
                if half == 0: lower_lo[a] = new_lo[a]; lower_hi[a] = new_hi[a]
                else: upper_lo[a] = new_lo[a]; upper_hi[a] = new_hi[a]
        for a in range(3): lo[3*selected+a] = upper_lo[a]; hi[3*selected+a] = upper_hi[a]
        totals[selected] = upper_total
        var i = box_count
        while i > 0:
            totals[i] = totals[i-1]
            for a in range(3): lo[3*i+a] = lo[3*(i-1)+a]; hi[3*i+a] = hi[3*(i-1)+a]
            i -= 1
        totals[0] = lower_total
        for a in range(3): lo[a] = lower_lo[a]; hi[a] = lower_hi[a]
        box_count += 1
    let bytes = 1+3*box_count
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes): return -2
    output[0] = UInt8(box_count)
    for i in range(box_count):
        for axis in range(3): output[1+3*i+axis] = UInt8(4*(lo[3*i+axis]+hi[3*i+axis]))
    return Int64(bytes)
