const MAX_INPUT_LENGTH: usize = 24;

fn exact_integer(value: f64, low: i64, high: i64) -> Option<i64> {
    if value.is_finite() && value >= low as f64 && value <= high as f64 && value.trunc() == value {
        Some(value as i64)
    } else { None }
}

fn evaluate(p: usize, n: usize, u: f64, knots: &[f64], controls: &[f64]) -> f64 {
    let mut span = p;
    if u == knots[n] { span = n-1; }
    else { while span < n-1 && u >= knots[span+1] { span += 1; } }
    let mut local = [0.0_f64; 4];
    for j in 0..=p { local[j] = controls[span-p+j]; }
    for level in 1..=p {
        for slot in (level..=p).rev() {
            let left = span-p+slot;
            let right = span+slot-level+1;
            let denominator = knots[right]-knots[left];
            let alpha = if denominator == 0.0 { 0.0 } else { (u-knots[left])/denominator };
            local[slot] = (1.0-alpha)*local[slot-1]+alpha*local[slot];
        }
    }
    local[p]
}

#[no_mangle]
pub unsafe extern "C" fn de_boor_bspline_curve_evaluation(
    input: *const f64, input_length: usize, output: *mut f64, output_capacity: usize,
) -> i64 {
    if input.is_null() || input_length < 3 || input_length > MAX_INPUT_LENGTH { return -1; }
    let values = std::slice::from_raw_parts(input,input_length);
    let Some(p_value) = exact_integer(values[0],1,3) else { return -1; };
    let p = p_value as usize;
    let Some(n_value) = exact_integer(values[1],(p+1) as i64,8) else { return -1; };
    if !values[2].is_finite() { return -1; }
    let n = n_value as usize;
    let knot_count = n+p+1;
    if input_length != 3+knot_count+n { return -1; }
    let knots = &values[3..3+knot_count];
    let controls = &values[3+knot_count..];
    if knots.iter().any(|x| !x.is_finite() || *x < -1000.0 || *x > 1000.0) ||
        knots.windows(2).any(|pair| pair[0] > pair[1]) ||
        controls.iter().any(|x| !x.is_finite() || *x < -1000.0 || *x > 1000.0) { return -1; }
    let mut run = 1;
    for pair in knots.windows(2) {
        run = if pair[0] == pair[1] { run+1 } else { 1 };
        if run > p+1 { return -1; }
    }
    let u = values[2];
    if !(knots[p] < knots[n] && u >= knots[p] && u <= knots[n]) { return -1; }
    if output.is_null() || output_capacity < 1 { return -2; }
    let result = evaluate(p,n,u,knots,controls);
    if !result.is_finite() { return -1; }
    output.write(result);
    1
}
