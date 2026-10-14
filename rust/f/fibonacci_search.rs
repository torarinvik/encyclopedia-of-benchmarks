/// Fibonacci search in an ascending sequence for the shared benchmark contract.
#[no_mangle]
pub extern "C" fn fibonacci_search(values: *const i64, length: usize, target: i64) -> i64 {
    if length == 0 {
        return -1;
    }
    // The C caller guarantees a valid array of `length` elements.
    let values = unsafe { std::slice::from_raw_parts(values, length) };
    let mut fib_minus_two = 0usize;
    let mut fib_minus_one = 1usize;
    let mut fib = 1usize;
    while fib < length {
        fib_minus_two = fib_minus_one;
        fib_minus_one = fib;
        fib = fib_minus_two + fib_minus_one;
    }

    let mut offset_plus_one = 0usize;
    while fib > 1 {
        let mut index = offset_plus_one + fib_minus_two - 1;
        if index >= length {
            index = length - 1;
        }
        let value = values[index];
        if value == target {
            return index as i64;
        }
        if value < target {
            fib = fib_minus_one;
            fib_minus_one = fib_minus_two;
            fib_minus_two = fib - fib_minus_one;
            offset_plus_one = index + 1;
        } else {
            fib = fib_minus_two;
            fib_minus_one -= fib_minus_two;
            fib_minus_two = fib - fib_minus_one;
        }
    }
    if fib_minus_one != 0 && offset_plus_one < length && values[offset_plus_one] == target {
        return offset_plus_one as i64;
    }
    -1
}
