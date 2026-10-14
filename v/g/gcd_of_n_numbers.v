module gcd_of_n_numbers

fn gcd_pair(left_input i64, right_input i64) i64 {
    mut left := left_input
    mut right := right_input
    for right != 0 {
        remainder := left % right
        left = right
        right = remainder
    }
    return left
}

@[export: 'gcd_of_n_numbers']
pub fn gcd_of_n_numbers(values &i64, length usize) i64 {
    if length == 0 || length > 64 { return -1 }
    for index := usize(0); index < length; index++ {
        value := unsafe { values[index] }
        if value < 1 || value > 2147483647 { return -1 }
    }
    mut result := unsafe { values[0] }
    for index := usize(1); index < length && result != 1; index++ {
        result = gcd_pair(result, unsafe { values[index] })
    }
    return result
}
