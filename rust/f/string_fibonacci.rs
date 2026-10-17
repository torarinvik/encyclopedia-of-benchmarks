const MAX_N: i64 = 256;
const DECIMAL_CAPACITY: usize = 80;

fn add_decimal(
    left: &[u8; DECIMAL_CAPACITY],
    left_length: usize,
    right: &[u8; DECIMAL_CAPACITY],
    right_length: usize,
    result: &mut [u8; DECIMAL_CAPACITY],
) -> usize {
    let mut reversed = [0u8; DECIMAL_CAPACITY];
    let (mut left_remaining, mut right_remaining) = (left_length, right_length);
    let (mut length, mut carry) = (0usize, 0u8);
    while left_remaining > 0 || right_remaining > 0 || carry != 0 {
        let left_digit = if left_remaining > 0 {
            left_remaining -= 1;
            left[left_remaining] - b'0'
        } else { 0 };
        let right_digit = if right_remaining > 0 {
            right_remaining -= 1;
            right[right_remaining] - b'0'
        } else { 0 };
        let sum = left_digit + right_digit + carry;
        reversed[length] = b'0' + (sum % 10);
        length += 1;
        carry = sum / 10;
    }
    for i in 0..length { result[i] = reversed[length - 1 - i]; }
    result[length] = 0;
    length
}

#[no_mangle]
pub unsafe extern "C" fn string_fibonacci(
    input: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if input.is_null() || length != 1 { return -1; }
    let n = *input;
    if n < 0 || n > MAX_N { return -1; }

    let mut fib_minus_one = [0u8; DECIMAL_CAPACITY];
    let mut fib_minus_two = [0u8; DECIMAL_CAPACITY];
    fib_minus_one[0] = b'1';
    fib_minus_two[0] = b'0';
    let (mut minus_one_length, mut minus_two_length) = (1usize, 1usize);
    for _ in 0..n as usize {
        let mut sum = [0u8; DECIMAL_CAPACITY];
        let sum_length = add_decimal(
            &fib_minus_one, minus_one_length, &fib_minus_two, minus_two_length, &mut sum,
        );
        for i in 0..minus_one_length { fib_minus_two[i] = fib_minus_one[i]; }
        minus_two_length = minus_one_length;
        for i in 0..sum_length { fib_minus_one[i] = sum[i]; }
        fib_minus_one[sum_length] = 0;
        minus_one_length = sum_length;
    }

    if output.is_null() || capacity < minus_two_length { return -2; }
    std::ptr::copy_nonoverlapping(fib_minus_two.as_ptr(), output, minus_two_length);
    minus_two_length as i64
}
