const MAX_LIMIT: i64 = 10_000_000;
const MAX_DIGITS: usize = 7;
const MAX_SUM: usize = MAX_DIGITS * 81 + 1;

fn digit_square_sum(mut value: u32) -> u32 {
    let mut total = 0;
    while value != 0 {
        let digit = value % 10;
        total += digit * digit;
        value /= 10;
    }
    total
}

fn reaches_89(mut value: u32) -> bool {
    while value != 1 && value != 89 { value = digit_square_sum(value); }
    value == 89
}

#[no_mangle]
pub extern "C" fn problem92(number: i64) -> i64 {
    if !(0..=MAX_LIMIT).contains(&number) { return -1; }
    let mut digits = [0u32; MAX_DIGITS];
    let mut reversed = [0u32; MAX_DIGITS];
    let mut digit_count = 0usize;
    if number > 1 {
        let mut remaining = (number - 1) as u32;
        while remaining != 0 {
            reversed[digit_count] = remaining % 10;
            digit_count += 1;
            remaining /= 10;
        }
        for index in 0..digit_count { digits[index] = reversed[digit_count - index - 1]; }
    } else {
        digits[0] = 0;
        digit_count = 1;
    }
    let sum_limit = digit_count * 81 + 1;
    let mut tight = [0i64; MAX_SUM];
    let mut free_counts = [0i64; MAX_SUM];
    let mut next_tight = [0i64; MAX_SUM];
    let mut next_free = [0i64; MAX_SUM];
    tight[0] = 1;
    for position in 0..digit_count {
        next_tight.fill(0);
        next_free.fill(0);
        let bound_digit = digits[position];
        for sum in 0..sum_limit {
            if tight[sum] != 0 {
                for digit in 0..=bound_digit {
                    let next_sum = sum + (digit * digit) as usize;
                    if next_sum >= sum_limit { continue; }
                    if digit == bound_digit { next_tight[next_sum] += tight[sum]; }
                    else { next_free[next_sum] += tight[sum]; }
                }
            }
            if free_counts[sum] != 0 {
                for digit in 0..=9u32 {
                    let next_sum = sum + (digit * digit) as usize;
                    if next_sum < sum_limit { next_free[next_sum] += free_counts[sum]; }
                }
            }
        }
        tight = next_tight;
        free_counts = next_free;
    }
    let mut result = 0i64;
    for sum in 1..sum_limit {
        if reaches_89(sum as u32) { result += tight[sum] + free_counts[sum]; }
    }
    result
}
