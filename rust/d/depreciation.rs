const MAX_YEARS: usize = 16;
const MAX_VALUE_MICRO: i64 = 1_000_000_000_000;
const MAX_RATE_PPM: i64 = 1_000_000;
const MAX_UNITS: i64 = 1_000_000_000;

fn write_f64_le(output: *mut u8, offset: usize, value: f64) {
    let bits = value.to_bits();
    for byte in 0..8 {
        unsafe { *output.add(offset + byte) = (bits >> (8 * byte)) as u8; }
    }
}

#[no_mangle]
pub unsafe extern "C" fn depreciation(
    values: *const i64, length: usize, output: *mut u8, output_capacity: usize,
) -> i64 {
    if values.is_null() || length < 4 || length > MAX_YEARS + 4 { return -1; }
    let input = std::slice::from_raw_parts(values, length);
    let method = input[0];
    let mut years = 0usize;
    let mut purchase_scaled = 0i64;
    let mut residual_scaled = 0i64;
    let mut rate = 0.0f64;
    if method == 0 || method == 3 || method == 4 {
        if length != 4 || input[1] < 1 || input[1] > MAX_YEARS as i64 { return -1; }
        years = input[1] as usize;
        purchase_scaled = input[2]; residual_scaled = input[3];
    } else if method == 1 {
        if length != 5 || input[1] < 1 || input[1] > MAX_YEARS as i64
            || input[4] < 1 || input[4] > MAX_RATE_PPM { return -1; }
        years = input[1] as usize;
        purchase_scaled = input[2]; residual_scaled = input[3];
        rate = input[4] as f64 / 1_000_000.0;
    } else if method == 2 {
        if length < 5 { return -1; }
        years = length - 4;
        if years > MAX_YEARS || input[3] < 1 || input[3] > MAX_UNITS { return -1; }
        purchase_scaled = input[1]; residual_scaled = input[2];
        let mut unit_sum = 0.0;
        for units in &input[4..] {
            if *units < -MAX_UNITS || *units > MAX_UNITS { return -1; }
            unit_sum += *units as f64;
        }
        if (unit_sum - input[3] as f64).abs() > 1.0e-6 * input[3] as f64 { return -1; }
    } else { return -1; }

    if purchase_scaled < 0 || purchase_scaled > MAX_VALUE_MICRO
        || residual_scaled < -MAX_VALUE_MICRO || residual_scaled > purchase_scaled { return -1; }
    let purchase = purchase_scaled as f64 / 1_000_000.0;
    let residual = residual_scaled as f64 / 1_000_000.0;
    let depreciable_cost = purchase - residual;
    let mut schedule = [0.0f64; MAX_YEARS];

    if method == 0 {
        let annual = depreciable_cost / years as f64;
        let mut accumulated = 0.0;
        for period in 0..years {
            if period == years - 1 { schedule[period] = depreciable_cost - accumulated; }
            else { accumulated += annual; schedule[period] = annual; }
        }
    } else if method == 1 {
        let mut book_value = purchase;
        for period in 0..years {
            if period == years - 1 { schedule[period] = book_value - residual; }
            else {
                let expense = (book_value * rate).min(book_value - residual);
                schedule[period] = expense;
                book_value -= expense;
            }
        }
    } else if method == 2 {
        let per_unit = depreciable_cost / input[3] as f64;
        let mut accumulated = 0.0;
        for period in 0..years {
            if period == years - 1 { schedule[period] = depreciable_cost - accumulated; }
            else {
                let expense = input[4 + period] as f64 * per_unit;
                accumulated += expense;
                schedule[period] = expense;
            }
        }
    } else if method == 3 {
        let syd = years as f64 * (years as f64 + 1.0) / 2.0;
        let mut accumulated = 0.0;
        for period in 1..=years {
            if period == years { schedule[period - 1] = depreciable_cost - accumulated; }
            else {
                let expense = ((years - period + 1) as f64 / syd) * depreciable_cost;
                accumulated += expense;
                schedule[period - 1] = expense;
            }
        }
    } else {
        let ddb_rate = 2.0 / years as f64;
        let mut book_value = purchase;
        let mut accumulated = 0.0;
        for period in 1..=years {
            let remaining = (years - period + 1) as f64;
            let ddb = (book_value * ddb_rate).max(0.0);
            let straight_line = ((book_value - residual) / remaining).max(0.0);
            let expense = ddb.max(straight_line).min(book_value - residual);
            if period == years { schedule[period - 1] = depreciable_cost - accumulated; }
            else { accumulated += expense; schedule[period - 1] = expense; book_value -= expense; }
        }
    }

    let output_bytes = years * 8;
    if output.is_null() || output_bytes > output_capacity { return -2; }
    for index in 0..years { write_f64_le(output, index * 8, schedule[index]); }
    output_bytes as i64
}
