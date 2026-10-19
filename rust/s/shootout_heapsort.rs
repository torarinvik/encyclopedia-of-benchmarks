const MAX_LENGTH: usize = 8192;
const OUTPUT_BYTES: usize = 9;
const MODULUS: i64 = 139_968;
const MULTIPLIER: i64 = 3_877;
const INCREMENT: i64 = 29_573;

fn source_heapsort(n: usize, values: &mut [f64; MAX_LENGTH + 1]) {
    let mut ir = n;
    let mut l = (n / 2) + 1;
    loop {
        let rra: f64;
        if l > 1 {
            l -= 1;
            rra = values[l];
        } else {
            rra = values[ir];
            values[ir] = values[1];
            ir -= 1;
            if ir == 1 {
                values[1] = rra;
                return;
            }
        }
        let mut i = l;
        let mut j = l * 2;
        while j <= ir {
            if j < ir && values[j] < values[j + 1] { j += 1; }
            if rra < values[j] {
                values[i] = values[j];
                i = j;
                j += i;
            } else {
                j = ir + 1;
            }
        }
        values[i] = rra;
    }
}

fn write_fixed_six(value: f64, output: *mut u8) {
    let millionths = (value * 1_000_000.0 + 0.5) as u32;
    let whole = millionths / 1_000_000;
    let mut fraction = millionths % 1_000_000;
    unsafe {
        *output.add(0) = b'0' + whole as u8;
        *output.add(1) = b'.';
        let mut divisor = 100_000;
        for index in 2..8 {
            *output.add(index) = b'0' + ((fraction / divisor) % 10) as u8;
            divisor /= 10;
        }
        *output.add(8) = b'\n';
    }
}

#[no_mangle]
pub extern "C" fn shootout_heapsort(length: i64, output: *mut u8,
                                     output_capacity: usize) -> i64 {
    if !(2..=MAX_LENGTH as i64).contains(&length) { return -1; }
    if output.is_null() || output_capacity < OUTPUT_BYTES { return -2; }

    let n = length as usize;
    let mut values = [0.0_f64; MAX_LENGTH + 1];
    let mut state = 42_i64;
    for value in values.iter_mut().take(n + 1).skip(1) {
        state = (state * MULTIPLIER + INCREMENT) % MODULUS;
        *value = 1.0 * state as f64 / MODULUS as f64;
    }
    source_heapsort(n, &mut values);
    write_fixed_six(values[n], output);
    OUTPUT_BYTES as i64
}
