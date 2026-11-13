const MAX_INPUT_LENGTH: usize = 6;
const MAX_INTERVALS: usize = 16;
const NODES: [f64; 7] = [
    0.9914553711208126392, 0.9491079123427585245, 0.8648644233597690728,
    0.7415311855993944399, 0.5860872354676911303, 0.4058451513773971669,
    0.2077849550078984676,
];
const KW: [f64; 7] = [
    0.022935322010529225, 0.06309209262997855, 0.10479001032225018,
    0.14065325971552592, 0.16900472663926790, 0.19035057806478541,
    0.20443294007529889,
];
const GW: [f64; 3] = [0.12948496616886969, 0.27970539148927667, 0.38183005050511894];

#[derive(Copy, Clone, Default)]
struct Interval {
    left: f64,
    right: f64,
    value: f64,
    error: f64,
}

fn exact_integer(x: f64, low: i64, high: i64) -> bool {
    x.is_finite() && x >= low as f64 && x <= high as f64 && x.trunc() == x
}

fn sample(id: i64, x: f64) -> f64 {
    match id {
        0 => (4.0 * x).exp(),
        1 => (10.0 * x).sin(),
        2 => 1.0 / (1.0 + 9.0 * x * x),
        _ => {
            let x2 = x * x;
            let x4 = x2 * x2;
            let x8 = x4 * x4;
            x8 * x4 * x2
        }
    }
}

fn pair_estimate(id: i64, a: f64, b: f64) -> (f64, f64) {
    let center = (a + b) * 0.5;
    let half = (b - a) * 0.5;
    let fc = sample(id, center);
    let mut ksum = 0.2094821410847278280 * fc;
    let mut gsum = 0.4179591836734693878 * fc;
    for index in 0..7 {
        let offset = half * NODES[index];
        let pair = sample(id, center - offset) + sample(id, center + offset);
        ksum += KW[index] * pair;
        if index == 1 { gsum += GW[0] * pair; }
        if index == 3 { gsum += GW[1] * pair; }
        if index == 5 { gsum += GW[2] * pair; }
    }
    (half * ksum, half * gsum)
}

#[no_mangle]
pub unsafe extern "C" fn adaptive_gauss_kronrod_15_quadrature(
    input: *const f64, input_length: usize, output: *mut f64, output_capacity: usize,
) -> i64 {
    if input.is_null() || input_length != 5 || input_length > MAX_INPUT_LENGTH { return -1; }
    let values = std::slice::from_raw_parts(input, input_length);
    if !exact_integer(values[0], 0, 3)
        || !exact_integer(values[1], -1_000_000, 1_000_000)
        || !exact_integer(values[2], -1_000_000, 1_000_000)
        || !exact_integer(values[3], 6, 8)
        || !exact_integer(values[4], 1, MAX_INTERVALS as i64) { return -1; }
    let id = values[0] as i64;
    let a_micro = values[1] as i64;
    let b_micro = values[2] as i64;
    let exponent = values[3] as i64;
    let limit = values[4] as usize;
    if a_micro > b_micro { return -1; }
    if output.is_null() || output_capacity < 1 { return -2; }
    let a = a_micro as f64 / 1_000_000.0;
    let b = b_micro as f64 / 1_000_000.0;
    if a == b { output.write(0.0); return 1; }
    let mut intervals = [Interval::default(); MAX_INTERVALS];
    let (k, g) = pair_estimate(id, a, b);
    intervals[0] = Interval { left: a, right: b, value: k, error: (k - g).abs() };
    let mut count = 1;
    let mut tolerance = 1.0;
    for _ in 0..exponent { tolerance *= 0.1; }
    loop {
        let mut total = 0.0;
        let mut error = 0.0;
        for interval in intervals.iter().take(count) {
            total += interval.value;
            error += interval.error;
        }
        if error <= tolerance * 1.0_f64.max(total.abs()) {
            if !total.is_finite() { return -1; }
            output.write(total);
            return 1;
        }
        if count >= limit { return -3; }
        let mut best = 0;
        for index in 1..count {
            if intervals[index].error > intervals[best].error
                || (intervals[index].error == intervals[best].error
                    && intervals[index].left < intervals[best].left) {
                best = index;
            }
        }
        let left = intervals[best].left;
        let right = intervals[best].right;
        let middle = (left + right) * 0.5;
        let (lk, lg) = pair_estimate(id, left, middle);
        let (rk, rg) = pair_estimate(id, middle, right);
        intervals[best] = Interval { left, right: middle, value: lk, error: (lk - lg).abs() };
        intervals[count] = Interval { left: middle, right, value: rk, error: (rk - rg).abs() };
        count += 1;
    }
}
