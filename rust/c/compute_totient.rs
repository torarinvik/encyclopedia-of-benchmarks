fn decimal_length(mut value: i64) -> usize {
    let mut length = 1usize;
    while value >= 10 { value /= 10; length += 1; }
    length
}

fn append_decimal(mut value: i64, output: &mut [u8], mut position: usize) -> usize {
    let mut digits = [0u8; 3];
    let mut count = 0usize;
    loop {
        digits[count] = (value % 10) as u8;
        count += 1;
        value /= 10;
        if value == 0 { break; }
    }
    while count > 0 {
        count -= 1;
        output[position] = b'0' + digits[count];
        position += 1;
    }
    position
}

#[no_mangle]
pub extern "C" fn compute_totient(n: i64, output: *mut u8, output_capacity: usize) -> i64 {
    if n < 1 || n > 80 { return -1; }
    let n = n as usize;
    let mut phi = [0i64; 80];
    for i in 1..=n { phi[i - 1] = i as i64; }
    for p in 2..=n {
        if phi[p - 1] != p as i64 { continue; }
        phi[p - 1] = p as i64 - 1;
        let mut i = 2 * p;
        while i <= n {
            phi[i - 1] = (phi[i - 1] / p as i64) * (p as i64 - 1);
            i += p;
        }
    }
    let required: usize = phi[..n].iter().map(|&v| decimal_length(v)).sum::<usize>() + n - 1;
    if output.is_null() || output_capacity < required { return -2; }
    let bytes = unsafe { std::slice::from_raw_parts_mut(output, required) };
    let mut position = 0usize;
    for index in 0..n {
        if index > 0 { bytes[position] = b','; position += 1; }
        position = append_decimal(phi[index], bytes, position);
    }
    position as i64
}
