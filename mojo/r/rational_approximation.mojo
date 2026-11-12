from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn gcd_positive(left_input: Int64, right_input: Int64) -> Int64:
    var left = left_input
    var right = right_input
    while right != 0:
        var remainder = left % right
        left = right
        right = remainder
    return left

fn store_i64_le(value: Int64, output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int):
    var bits = UInt64(value)
    for byte in range(8):
        output[offset + byte] = UInt8((bits >> (byte * 8)) & 0xff)

@export("rational_approximation")
fn rational_approximation(values: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                          output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if values == UnsafePointer[Int64, ImmutAnyOrigin]() or length != 3: return -1
    var limit = values[0]
    var x = values[1]
    var y = values[2]
    if limit < 1 or limit > 1000000000 or x < 1 or x > 1000000000 or y < 1 or y > 1000000000:
        return -1
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < 32: return -2

    var divisor = gcd_positive(x, y)
    var reduced_x = x // divisor
    var reduced_y = y // divisor
    var a: Int64 = 0
    var b: Int64 = 1
    var c: Int64 = 1
    var d: Int64 = 0
    if reduced_x <= limit and reduced_y <= limit:
        a = reduced_x
        b = reduced_y
        c = reduced_x
        d = reduced_y
    else:
        var searching = True
        while searching:
            var middle_num = a + c
            var middle_den = b + d
            if middle_num > limit or middle_den > limit:
                searching = False
            else:
                var target_side = middle_num * y
                var middle_side = middle_den * x
                if target_side == middle_side:
                    a = middle_num
                    b = middle_den
                    c = middle_num
                    d = middle_den
                    searching = False
                elif target_side < middle_side:
                    var lower_gap = b * x - a * y
                    var upper_gap = c * y - d * x
                    var step = lower_gap // upper_gap
                    var numerator_cap = (limit - a) // c
                    if step > numerator_cap: step = numerator_cap
                    if d > 0:
                        var denominator_cap = (limit - b) // d
                        if step > denominator_cap: step = denominator_cap
                    a += step * c
                    b += step * d
                else:
                    var upper_gap = c * y - d * x
                    var lower_gap = b * x - a * y
                    var step = upper_gap // lower_gap
                    if a > 0:
                        var numerator_cap = (limit - c) // a
                        if step > numerator_cap: step = numerator_cap
                    var denominator_cap = (limit - d) // b
                    if step > denominator_cap: step = denominator_cap
                    c += step * a
                    d += step * b

    store_i64_le(a, output, 0)
    store_i64_le(b, output, 8)
    store_i64_le(c, output, 16)
    store_i64_le(d, output, 24)
    return 32
