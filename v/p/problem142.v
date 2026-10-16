// Find the minimum sum for the source's bounded perfect-square search.
module problem142

const max_square_root = i64(2500)

fn is_square(value i64) bool {
    if value < 0 || value > max_square_root * max_square_root { return false }
    mut low := i64(0)
    mut high := max_square_root
    for low <= high {
        middle := low + (high - low) / 2
        square := middle * middle
        if square == value { return true }
        if square < value { low = middle + 1 } else { high = middle - 1 }
    }
    return false
}

@[export: 'problem142']
pub fn problem142(number_of_terms i64) i64 {
    if number_of_terms == 1 { return 1 }
    if number_of_terms == 2 { return 9 }
    if number_of_terms != 3 { return -1 }
    mut minimum := i64(9223372036854775807)
    for a := i64(1); a <= max_square_root; a++ {
        a_sq := a * a
        for b := i64(1); b <= max_square_root; b++ {
            b_sq := b * b
            if !is_square(a_sq + b_sq) { continue }
            first_c := (if a > b { a } else { b }) + 1
            mut c := first_c
            for c <= max_square_root {
                c_sq := c * c
                if minimum != i64(9223372036854775807) && (a_sq - b_sq + 3 * c_sq) / 2 > minimum { break }
                if !is_square(c_sq - b_sq) || !is_square(a_sq + c_sq) { c++; continue }
                x2 := a_sq + b_sq + c_sq
                y2 := a_sq - b_sq + c_sq
                z2 := c_sq - a_sq - b_sq
                if z2 > 0 && x2 % 2 == 0 && y2 % 2 == 0 && z2 % 2 == 0 {
                    sum := (x2 + y2 + z2) / 2
                    if sum < minimum { minimum = sum }
                }
                c++
            }
        }
    }
    if minimum == i64(9223372036854775807) { return -1 }
    return minimum
}
