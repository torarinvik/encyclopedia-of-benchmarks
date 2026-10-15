/// Minimum number of perfect squares summing to value, using Lagrange's theorem.
#[no_mangle]
pub extern "C" fn sum_of_squares(value: i64) -> i64 {
    if value < 0 || value > 2_147_483_647 { return -1; }
    if value == 0 { return 0; }

    let mut low = 1_i64;
    let mut high = value;
    while high - low > 1 {
        let middle = low + (high - low) / 2;
        if middle <= value / middle { low = middle; }
        else { high = middle; }
    }
    let root = low;
    if root * root == value { return 1; }

    let mut second = root;
    for first in 1..=root {
        let remainder = value - first * first;
        while second * second > remainder { second -= 1; }
        if second * second == remainder { return 2; }
    }

    let mut reduced = value;
    while reduced % 4 == 0 { reduced /= 4; }
    if reduced % 8 == 7 { 4 } else { 3 }
}
