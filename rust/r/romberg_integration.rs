const MAX_INPUT_LENGTH: usize = 5;

fn integer_field(value: f64, low: i64, high: i64) -> Option<i64> {
    if value.is_finite() && value >= low as f64 && value <= high as f64 && value.trunc() == value {
        Some(value as i64)
    } else { None }
}

fn integrand(id: i64, x: f64) -> f64 {
    match id { 0 => x.exp(), 1 => x*x*x*x*x, 2 => 1.0/(1.0+x*x), _ => x.cos() }
}

fn romberg(id: i64, a: f64, b: f64, levels: i64) -> f64 {
    if a == b { return 0.0; }
    let mut previous = [0.0_f64; 9];
    previous[0] = (b-a)*(integrand(id,a)+integrand(id,b))*0.5;
    for level in 1..=levels as usize {
        let interval_count = 1_usize << level;
        let spacing = (b-a)/interval_count as f64;
        let mut added = 0.0;
        for index in (1..interval_count).step_by(2) {
            added += integrand(id,a+index as f64*spacing);
        }
        let mut current = [0.0_f64; 9];
        current[0] = previous[0]*0.5+spacing*added;
        let mut factor = 4.0;
        for order in 1..=level {
            current[order]=current[order-1]+(current[order-1]-previous[order-1])/(factor-1.0);
            factor *= 4.0;
        }
        previous = current;
    }
    previous[levels as usize]
}

#[no_mangle]
pub unsafe extern "C" fn romberg_integration(
    input: *const f64, input_length: usize, output: *mut f64, output_capacity: usize,
) -> i64 {
    if input.is_null() || input_length != 4 || input_length > MAX_INPUT_LENGTH { return -1; }
    let values = std::slice::from_raw_parts(input, input_length);
    let Some(id) = integer_field(values[0],0,3) else { return -1; };
    let Some(a_micro) = integer_field(values[1],-1_000_000,1_000_000) else { return -1; };
    let Some(b_micro) = integer_field(values[2],-1_000_000,1_000_000) else { return -1; };
    let Some(levels) = integer_field(values[3],3,8) else { return -1; };
    if a_micro>b_micro { return -1; }
    if output.is_null() || output_capacity<1 { return -2; }
    let result=romberg(id,a_micro as f64/1_000_000.0,b_micro as f64/1_000_000.0,levels);
    if !result.is_finite() { return -1; }
    output.write(result);
    1
}
