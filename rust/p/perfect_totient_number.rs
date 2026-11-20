/// Decide whether the iterated Euler-totient chain sums to n.
#[no_mangle]
pub extern "C" fn perfect_totient_number(n: i64) -> i64 {
    if !(3..=65_535).contains(&n) {
        return -1;
    }
    let mut value = n;
    let mut total = 0i64;
    while value > 1 {
        let mut result = value;
        let mut remaining = value;
        let mut factor = 2i64;
        while factor <= remaining / factor {
            if remaining % factor == 0 {
                while remaining % factor == 0 {
                    remaining /= factor;
                }
                result -= result / factor;
            }
            factor += 1;
        }
        if remaining > 1 {
            result -= result / remaining;
        }
        value = result;
        total += value;
    }
    if total == n { 1 } else { 0 }
}
