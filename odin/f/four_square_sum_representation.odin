package four_square_sum_representation

import "core:c"

floor_sqrt :: proc(value: i64) -> i64 {
    root: i64 = 0
    for (root + 1) * (root + 1) <= value {
        root += 1
    }
    return root
}

@(export)
four_square_sum_representation :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
    if input == nil || length != 1 do return -1
    n := input[0]
    if n < 0 || n > 1024 do return -1

    a := floor_sqrt(n)
    for a >= 0 {
        remainder_a := n - a * a
        b_max := floor_sqrt(remainder_a)
        if b_max > a do b_max = a
        b := b_max
        for b >= 0 {
            remainder_b := remainder_a - b * b
            c_max := floor_sqrt(remainder_b)
            if c_max > b do c_max = b
            c := c_max
            for c >= 0 {
                remainder_c := remainder_b - c * c
                d := floor_sqrt(remainder_c)
                if d <= c && d * d == remainder_c {
                    return (((a * 33 + b) * 33 + c) * 33 + d)
                }
                c -= 1
            }
            b -= 1
        }
        a -= 1
    }
    return -2
}
