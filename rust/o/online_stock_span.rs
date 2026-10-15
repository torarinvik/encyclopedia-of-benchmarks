const MAX_DAYS: usize = 4095;

#[no_mangle]
pub unsafe extern "C" fn online_stock_span(
    input: *const i64, length: usize, output: *mut u8, output_capacity: usize,
) -> i64 {
    if input.is_null() || length < 2 { return -1; }
    let count_arg = *input;
    if !(1..=MAX_DAYS as i64).contains(&count_arg) { return -1; }
    let count = count_arg as usize;
    if length != count + 1 { return -1; }
    for day in 0..count {
        let price = *input.add(day + 1);
        if !(1..=100_000).contains(&price) { return -1; }
    }
    let output_bytes = count * 8;
    if output_capacity < output_bytes || output.is_null() { return -2; }

    let mut decreasing = [0usize; MAX_DAYS];
    let mut top = 0usize;
    for day in 0..count {
        let price = *input.add(day + 1);
        while top > 0 && *input.add(decreasing[top - 1] + 1) <= price { top -= 1; }
        let span = if top == 0 { day + 1 } else { day - decreasing[top - 1] };
        let encoded = span as u64;
        for byte in 0..8 {
            *output.add(day * 8 + byte) = (encoded >> (byte * 8)) as u8;
        }
        decreasing[top] = day;
        top += 1;
    }
    count as i64
}
