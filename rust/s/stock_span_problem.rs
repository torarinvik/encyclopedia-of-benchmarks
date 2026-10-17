/// Return source-compatible spans for a bounded price sequence.
#[no_mangle]
pub unsafe extern "C" fn stock_span_problem(
    input: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if input.is_null() || length < 2 || length > 66 {
        return -1;
    }
    let packed = std::slice::from_raw_parts(input, length);
    let count_value = packed[0];
    if !(1..=64).contains(&count_value) {
        return -1;
    }
    let count = count_value as usize;
    if length != count + 1 {
        return -1;
    }
    let prices = &packed[1..];
    if prices.iter().any(|&price| price < i32::MIN as i64 || price > i32::MAX as i64) {
        return -1;
    }
    let output_bytes = count * 8;
    if output.is_null() || capacity < output_bytes {
        return -2;
    }

    let mut decreasing = [0usize; 64];
    let mut top = 0usize;
    for day in 0..count {
        let price = prices[day];
        while top > 0 && prices[decreasing[top - 1]] <= price { top -= 1; }
        let span = if top == 0 { day + 1 } else { day - decreasing[top - 1] };
        for byte in 0..8 {
            *output.add(day * 8 + byte) = ((span as u64) >> (byte * 8)) as u8;
        }
        decreasing[top] = day;
        top += 1;
    }
    count as i64
}
