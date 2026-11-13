from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

fn insert_line(mut slopes: InlineArray[Int64, 136], mut intercepts: InlineArray[Int64, 136],
               mut occupied: InlineArray[Bool, 136], start: Int, low_start: Int,
               high_start: Int, slope: Int64, intercept: Int64):
    var node = start
    var low = low_start
    var high = high_start
    var a = slope
    var b = intercept
    while True:
        if not occupied[node]:
            occupied[node] = True
            slopes[node] = a
            intercepts[node] = b
            return
        let middle = low + (high - low) // 2
        if a * Int64(middle) + b < slopes[node] * Int64(middle) + intercepts[node]:
            let old_a = slopes[node]
            let old_b = intercepts[node]
            slopes[node] = a
            intercepts[node] = b
            a = old_a
            b = old_b
        if low == high: return
        if a * Int64(low) + b < slopes[node] * Int64(low) + intercepts[node]:
            node *= 2
            high = middle
        elif a * Int64(high) + b < slopes[node] * Int64(high) + intercepts[node]:
            node = 2 * node + 1
            low = middle + 1
        else:
            return

fn insert_segment(mut slopes: InlineArray[Int64, 136], mut intercepts: InlineArray[Int64, 136],
                  mut occupied: InlineArray[Bool, 136], left: Int, right: Int,
                  slope: Int64, intercept: Int64):
    var l = left + 96
    var r = right + 96
    while l < r:
        if l % 2 == 1:
            var width = 64
            var ancestor = l
            while ancestor > 1:
                width //= 2
                ancestor //= 2
            let low = (l - 64 // width) * width - 32
            insert_line(mut slopes, mut intercepts, mut occupied, l, low, low + width - 1, slope, intercept)
            l += 1
        if r % 2 == 1:
            r -= 1
            var width = 64
            var ancestor = r
            while ancestor > 1:
                width //= 2
                ancestor //= 2
            let low = (r - 64 // width) * width - 32
            insert_line(mut slopes, mut intercepts, mut occupied, r, low, low + width - 1, slope, intercept)
        l //= 2
        r //= 2

@export("segment_add_get_min")
fn segment_add_get_min(values: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if values == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 226: return -1
    if values[0] < 0 or values[0] > 16 or values[1] < 0 or values[1] > 32: return -1
    let initial = Int(values[0])
    let operations = Int(values[1])
    var slopes = InlineArray[Int64, 136](fill=0)
    var intercepts = InlineArray[Int64, 136](fill=0)
    var occupied = InlineArray[Bool, 136](fill=False)
    var pos = 2
    var checksum: Int64 = 0
    var query: Int64 = 0
    for step in range(initial + operations):
        var opcode: Int64 = 0
        if step >= initial:
            if c_size_t(pos) >= length: return -1
            opcode = values[pos]
            pos += 1
        if opcode == 0:
            if c_size_t(pos + 4) > length: return -1
            let left = values[pos]
            let right = values[pos + 1]
            let slope = values[pos + 2]
            let intercept = values[pos + 3]
            pos += 4
            if left < -32 or left >= right or right > 32 or slope < -1000 or slope > 1000 or intercept < -1000 or intercept > 1000: return -1
            insert_segment(mut slopes, mut intercepts, mut occupied, Int(left), Int(right), slope, intercept)
        elif opcode == 1:
            if c_size_t(pos) >= length: return -1
            let x = values[pos]
            pos += 1
            if x < -32 or x > 31: return -1
            var node = Int(x) + 96
            var best: Int64 = 1000000000000
            while node > 0:
                if occupied[node]:
                    let value = slopes[node] * x + intercepts[node]
                    if value < best: best = value
                node //= 2
            query += 1
            checksum += query * (best + 33001)
        else:
            return -1
    if c_size_t(pos) != length: return -1
    return checksum
