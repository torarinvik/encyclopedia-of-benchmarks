const MAX_NUMBER: i64 = 4096;
const STACK_CAPACITY: usize = 4112;

#[no_mangle]
pub unsafe extern "C" fn lexicographical_numbers(values: *const i64, length: usize) -> i64 {
    if values.is_null() || length != 1 { return -1; }
    let maximum = *values;
    if !(0..=MAX_NUMBER).contains(&maximum) { return -1; }
    let mut stack = [0_i64; STACK_CAPACITY];
    let mut top = 1;
    stack[0] = 1;
    let mut index = 0_i64;
    let mut checksum = 0_i64;
    while top > 0 {
        top -= 1;
        let number = stack[top];
        if number <= maximum {
            index += 1;
            checksum += index * number;
            if number % 10 != 9 { stack[top] = number + 1; top += 1; }
            stack[top] = number * 10;
            top += 1;
        }
    }
    checksum
}
