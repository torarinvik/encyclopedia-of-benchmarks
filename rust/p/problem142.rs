/// Find the minimum sum for the source's bounded perfect-square search.
const MAX_SQUARE_ROOT: i64 = 2_500;

fn is_square(value: i64) -> bool {
    if value < 0 || value > MAX_SQUARE_ROOT * MAX_SQUARE_ROOT { return false; }
    let mut low = 0i64;
    let mut high = MAX_SQUARE_ROOT;
    while low <= high {
        let middle = low + (high - low) / 2;
        let square = middle * middle;
        if square == value { return true; }
        if square < value { low = middle + 1; } else { high = middle - 1; }
    }
    false
}

#[no_mangle]
pub extern "C" fn problem142(number_of_terms: i64) -> i64 {
    if number_of_terms == 1 { return 1; }
    if number_of_terms == 2 { return 9; }
    if number_of_terms != 3 { return -1; }
    let mut minimum = i64::MAX;
    for a in 1..=MAX_SQUARE_ROOT {
        let a_sq = a * a;
        for b in 1..=MAX_SQUARE_ROOT {
            let b_sq = b * b;
            if !is_square(a_sq + b_sq) { continue; }
            let first_c = (if a > b { a } else { b }) + 1;
            for c in first_c..=MAX_SQUARE_ROOT {
                let c_sq = c * c;
                if minimum != i64::MAX && (a_sq - b_sq + 3 * c_sq) / 2 > minimum { break; }
                if !is_square(c_sq - b_sq) || !is_square(a_sq + c_sq) { continue; }
                let x2 = a_sq + b_sq + c_sq;
                let y2 = a_sq - b_sq + c_sq;
                let z2 = c_sq - a_sq - b_sq;
                if z2 > 0 && x2 % 2 == 0 && y2 % 2 == 0 && z2 % 2 == 0 {
                    let sum = (x2 + y2 + z2) / 2;
                    if sum < minimum { minimum = sum; }
                }
            }
        }
    }
    if minimum == i64::MAX { -1 } else { minimum }
}
