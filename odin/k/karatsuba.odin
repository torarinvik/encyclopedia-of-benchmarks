package karatsuba

import "core:c"

karatsuba_product :: proc(left, right: i64) -> i64 {
    if left < 10 || right < 10 do return left * right
    largest := left
    if right > largest do largest = right
    digits := 1
    for remaining := largest; remaining >= 10; remaining /= 10 { digits += 1 }
    split: i64 = 1
    for _ in 0..<digits/2 { split *= 10 }
    left_high, left_low := left / split, left % split
    right_high, right_low := right / split, right % split
    low_product := karatsuba_product(left_low, right_low)
    high_product := karatsuba_product(left_high, right_high)
    sum_product := karatsuba_product(left_high + left_low, right_high + right_low)
    return high_product * split * split + (sum_product - high_product - low_product) * split + low_product
}

@(export)
karatsuba :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
    if input == nil || length != 2 do return -1
    if input[0] < 0 || input[0] > 1_000_000 || input[1] < 0 || input[1] > 1_000_000 do return -1
    return karatsuba_product(input[0], input[1])
}
