// Find the minimum sum for the source's bounded perfect-square search.
package problem142

MAX_SQUARE_ROOT :: i64(2_500)

is_square :: proc(value: i64) -> bool {
    if value < 0 || value > MAX_SQUARE_ROOT * MAX_SQUARE_ROOT do return false
    low := i64(0)
    high := MAX_SQUARE_ROOT
    for low <= high {
        middle := low + (high - low) / 2
        square := middle * middle
        if square == value do return true
        if square < value { low = middle + 1 } else { high = middle - 1 }
    }
    return false
}

@(export)
problem142 :: proc "c" (number_of_terms: i64) -> i64 {
    if number_of_terms == 1 do return 1
    if number_of_terms == 2 do return 9
    if number_of_terms != 3 do return -1
    minimum := i64(0x7fffffffffffffff)
    for a := i64(1); a <= MAX_SQUARE_ROOT; a += 1 {
        a_sq := a * a
        for b := i64(1); b <= MAX_SQUARE_ROOT; b += 1 {
            b_sq := b * b
            if !is_square(a_sq + b_sq) do continue
            first_c := (if a > b { a } else { b }) + 1
            for c := first_c; c <= MAX_SQUARE_ROOT; c += 1 {
                c_sq := c * c
                if minimum != i64(0x7fffffffffffffff) && (a_sq - b_sq + 3 * c_sq) / 2 > minimum do break
                if !is_square(c_sq - b_sq) || !is_square(a_sq + c_sq) do continue
                x2 := a_sq + b_sq + c_sq
                y2 := a_sq - b_sq + c_sq
                z2 := c_sq - a_sq - b_sq
                if z2 > 0 && x2 % 2 == 0 && y2 % 2 == 0 && z2 % 2 == 0 {
                    sum := (x2 + y2 + z2) / 2
                    if sum < minimum { minimum = sum }
                }
            }
        }
    }
    if minimum == i64(0x7fffffffffffffff) do return -1
    return minimum
}
