const MAX_LENGTH: usize = 4096;

#[no_mangle]
pub extern "C" fn ary3(length: i64, output: *mut u8, output_capacity: usize) -> i64 {
    if length < 1 || length > MAX_LENGTH as i64 { return -1; }
    let n = length as usize;
    let mut x = [0_i32; MAX_LENGTH];
    let mut y = [0_i32; MAX_LENGTH];
    for index in 0..n {
        x[index] = (index + 1) as i32;
        y[index] = 0;
    }
    for _ in 0..1000 {
        for index in (0..n).rev() { y[index] += x[index]; }
    }

    let mut first = y[0] as u32;
    let mut last = y[n - 1] as u32;
    let mut first_reversed = [0_u8; 10];
    let mut first_digit_count = 0;
    while first > 0 {
        first_reversed[first_digit_count] = b'0' + (first % 10) as u8;
        first_digit_count += 1;
        first /= 10;
    }
    let mut reversed = [0_u8; 10];
    let mut digit_count = 0;
    while last > 0 {
        reversed[digit_count] = b'0' + (last % 10) as u8;
        digit_count += 1;
        last /= 10;
    }
    let required = first_digit_count + 2 + digit_count;
    if output.is_null() || output_capacity < required { return -2; }
    unsafe {
        for index in 0..first_digit_count {
            *output.add(index) = first_reversed[first_digit_count - index - 1];
        }
        *output.add(first_digit_count) = b' ';
        for index in 0..digit_count {
            *output.add(first_digit_count + 1 + index) = reversed[digit_count - index - 1];
        }
        *output.add(required - 1) = b'\n';
    }
    required as i64
}
