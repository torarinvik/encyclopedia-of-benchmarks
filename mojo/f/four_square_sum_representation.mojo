from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

fn four_square_floor_sqrt(value: Int64) -> Int64:
    var root: Int64 = 0
    while (root + 1) * (root + 1) <= value:
        root += 1
    return root

@export("four_square_sum_representation")
fn four_square_sum_representation(input: UnsafePointer[Int64, ImmutAnyOrigin],
                                 length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length != 1:
        return -1
    let n = input[0]
    if n < 0 or n > 1024:
        return -1

    var a = four_square_floor_sqrt(n)
    while a >= 0:
        let rem_a = n - a * a
        var b_max = four_square_floor_sqrt(rem_a)
        if b_max > a:
            b_max = a
        var b = b_max
        while b >= 0:
            let rem_b = rem_a - b * b
            var c_max = four_square_floor_sqrt(rem_b)
            if c_max > b:
                c_max = b
            var c = c_max
            while c >= 0:
                let rem_c = rem_b - c * c
                let d = four_square_floor_sqrt(rem_c)
                if d <= c and d * d == rem_c:
                    return (((a * 33 + b) * 33 + c) * 33 + d)
                c -= 1
            b -= 1
        a -= 1
    return -2
