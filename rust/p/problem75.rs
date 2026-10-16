const MAX_LIMIT: i64 = 1_500_000;

fn gcd_i64(mut left: i64, mut right: i64) -> i64 {
    while right != 0 { let remainder = left % right; left = right; right = remainder; }
    left
}

#[no_mangle]
pub extern "C" fn problem75(limit: i64) -> i64 {
    if limit > MAX_LIMIT { return -1; }
    if limit < 0 { return 0; }
    let bound = limit as usize;
    let mut frequency = vec![0_u8; bound + 1];
    let mut m = 2_i64;
    while 2 * m * (m + 1) <= limit {
        let mut n = (m % 2) + 1;
        while n < m {
            if gcd_i64(m, n) == 1 {
                let primitive_perimeter = 2 * m * (m + n);
                let mut perimeter = primitive_perimeter;
                while perimeter <= limit {
                    let index = perimeter as usize;
                    if frequency[index] < 2 { frequency[index] += 1; }
                    perimeter += primitive_perimeter;
                }
            }
            n += 2;
        }
        m += 1;
    }
    frequency.iter().skip(1).filter(|&&count| count == 1).count() as i64
}
