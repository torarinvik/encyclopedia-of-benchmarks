/// Preserve the digit-window recurrence used by the pinned C# checker.
#[no_mangle]
pub extern "C" fn keith_number_checker(number: i64) -> i64 {
    if !(2..=1000).contains(&number) {
        return -1;
    }
    let original = number;
    let mut temp = number;
    let mut digits = 0usize;
    while temp != 0 {
        digits += 1;
        temp /= 10;
    }

    let mut terms = vec![0i64; number as usize];
    temp = number;
    for i in (0..digits).rev() {
        terms[i] = temp % 10;
        temp /= 10;
    }

    let mut sum = 0i64;
    let mut k = digits;
    while sum < original {
        sum = 0;
        for j in 1..=digits {
            sum += terms[k - j];
        }
        terms[k] = sum;
        k += 1;
    }
    (sum == original) as i64
}
