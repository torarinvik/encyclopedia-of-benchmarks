from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import InlineArray

# Unverified divide-and-conquer tangent-merge hull draft.
fn dcth_cross(inout x: InlineArray[Int64, 32], inout y: InlineArray[Int64, 32], a: Int, b: Int, c: Int) -> Int64:
    return (x[b]-x[a])*(y[c]-y[a]) - (y[b]-y[a])*(x[c]-x[a])

fn dcth_chain(inout x: InlineArray[Int64, 32], inout y: InlineArray[Int64, 32],
              inout order: InlineArray[Int, 32], inout output: InlineArray[Int, 32],
              lo: Int, hi: Int, base: Int, upper: Bool) -> Int:
    if hi-lo == 1:
        output[base] = order[lo]
        return 1
    let middle = lo+(hi-lo)//2
    let left_capacity = middle-lo
    let left_n = dcth_chain(x, y, order, output, lo, middle, base, upper)
    let right_n = dcth_chain(x, y, order, output, middle, hi, base+left_capacity, upper)
    var i = left_n-1
    var j = 0
    var changed = True
    while changed:
        changed = False
        while i > 0:
            let sign = dcth_cross(x, y, output[base+i], output[base+left_capacity+j], output[base+i-1])
            if (upper and sign <= 0) or (not upper and sign >= 0): break
            i -= 1
            changed = True
        while j+1 < right_n:
            let sign = dcth_cross(x, y, output[base+i], output[base+left_capacity+j], output[base+left_capacity+j+1])
            if (upper and sign <= 0) or (not upper and sign >= 0): break
            j += 1
            changed = True
    let suffix = right_n-j
    for k in range(suffix): output[base+i+1+k] = output[base+left_capacity+j+k]
    return i+1+suffix

@export("divide_conquer_tangent_hull")
fn divide_conquer_tangent_hull(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                               output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 7 or length > 66: return -1
    if input[0] < 3 or input[0] > 32: return -1
    let n = Int(input[0])
    if length != c_size_t(1+2*n): return -1
    var x = InlineArray[Int64, 32](fill=0)
    var y = InlineArray[Int64, 32](fill=0)
    var order = InlineArray[Int, 32](fill=0)
    var scratch = InlineArray[Int, 32](fill=0)
    for i in range(n):
        x[i] = input[1+2*i]
        y[i] = input[2+2*i]
        if x[i] < -1000 or x[i] > 1000 or y[i] < -1000 or y[i] > 1000: return -1
        for j in range(i):
            if x[j] == x[i]: return -1
        order[i] = i
    for i in range(n):
        for j in range(i+1, n):
            for k in range(j+1, n):
                if dcth_cross(x, y, i, j, k) == 0: return -1
    var width = 1
    while width < n:
        var begin = 0
        while begin < n:
            let middle = min(begin+width, n)
            let finish = min(begin+2*width, n)
            var left = begin
            var right = middle
            var dest = begin
            while left < middle and right < finish:
                if x[order[right]] < x[order[left]]:
                    scratch[dest] = order[right]
                    right += 1
                else:
                    scratch[dest] = order[left]
                    left += 1
                dest += 1
            while left < middle:
                scratch[dest] = order[left]
                left += 1
                dest += 1
            while right < finish:
                scratch[dest] = order[right]
                right += 1
                dest += 1
            begin += 2*width
        for i in range(n): order[i] = scratch[i]
        width *= 2
    var lower = InlineArray[Int, 32](fill=0)
    var upper = InlineArray[Int, 32](fill=0)
    var hull = InlineArray[Int, 32](fill=0)
    let lower_n = dcth_chain(x, y, order, lower, 0, n, 0, False)
    let upper_n = dcth_chain(x, y, order, upper, 0, n, 0, True)
    var count = 0
    for i in range(lower_n):
        hull[count] = lower[i]
        count += 1
    var index = upper_n-1
    while index > 1:
        index -= 1
        hull[count] = upper[index]
        count += 1
    let byte_count = 16*count
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(byte_count): return -2
    for i in range(count):
        for axis in range(2):
            var value = x[hull[i]]
            if axis == 1: value = y[hull[i]]
            let bits = bitcast[UInt64](value)
            for b in range(8): output[16*i+8*axis+b] = UInt8((bits >> UInt64(8*b)) & 255)
    return Int64(byte_count)
