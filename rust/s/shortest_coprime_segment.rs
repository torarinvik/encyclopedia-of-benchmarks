/// Two-stack sliding window with aggregate GCD; output is LE i64 values.
const MAX_LENGTH: usize = 128;

fn gcd_positive(mut a: i64, mut b: i64) -> i64 {
    while b != 0 { let remainder = a % b; a = b; b = remainder; }
    a
}

fn push(value: i64, items: &mut [i64; MAX_LENGTH], aggregates: &mut [i64; MAX_LENGTH], length: &mut usize) {
    items[*length] = value;
    aggregates[*length] = if *length == 0 { value } else { gcd_positive(aggregates[*length - 1], value) };
    *length += 1;
}

#[no_mangle]
pub unsafe extern "C" fn shortest_coprime_segment(input: *const i64, length: usize,
    output: *mut u8, output_capacity: usize) -> i64 {
    if length > MAX_LENGTH || (length != 0 && input.is_null()) { return -1; }
    for i in 0..length { let value = *input.add(i); if !(1..=1000).contains(&value) { return -1; } }
    let mut front = [0i64; MAX_LENGTH];
    let mut front_gcd = [0i64; MAX_LENGTH];
    let mut back = [0i64; MAX_LENGTH];
    let mut back_gcd = [0i64; MAX_LENGTH];
    let (mut front_length, mut back_length) = (0usize, 0usize);
    let (mut left, mut best_start, mut best_length) = (0usize, 0usize, length + 1);
    for right in 0..length {
        push(*input.add(right), &mut back, &mut back_gcd, &mut back_length);
        let mut window_gcd = gcd_positive(
            if front_length > 0 { front_gcd[front_length - 1] } else { 0 },
            if back_length > 0 { back_gcd[back_length - 1] } else { 0 });
        while window_gcd == 1 {
            let current_length = right - left + 1;
            if current_length < best_length { best_length = current_length; best_start = left; }
            if front_length == 0 {
                while back_length > 0 {
                    back_length -= 1;
                    let value = back[back_length];
                    push(value, &mut front, &mut front_gcd, &mut front_length);
                }
            }
            front_length -= 1;
            left += 1;
            window_gcd = gcd_positive(
                if front_length > 0 { front_gcd[front_length - 1] } else { 0 },
                if back_length > 0 { back_gcd[back_length - 1] } else { 0 });
        }
    }
    if best_length > length { return 0; }
    let byte_count = best_length * 8;
    if output.is_null() || output_capacity < byte_count { return -2; }
    for i in 0..best_length {
        let value = *input.add(best_start + i) as u64;
        for byte in 0..8 { *output.add(8 * i + byte) = (value >> (8 * byte)) as u8; }
    }
    byte_count as i64
}
