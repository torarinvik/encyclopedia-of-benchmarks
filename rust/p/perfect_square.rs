/// Exact perfect-square check using integer binary search and division.
#[no_mangle]
pub extern "C" fn perfect_square(input: i64) -> i64 {
    if input < 0 {
        return 0;
    }
    if input < 2 {
        return 1;
    }
    let number = input as u64;
    let mut low = 1_u64;
    let mut high = number / 2;
    while low <= high {
        let middle = low + (high - low) / 2;
        let quotient = number / middle;
        if quotient == middle {
            if number % middle == 0 {
                return 1;
            }
            low = middle + 1;
        } else if quotient < middle {
            high = middle - 1;
        } else {
            low = middle + 1;
        }
    }
    0
}
