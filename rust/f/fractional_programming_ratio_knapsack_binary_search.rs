const MAX_ITEMS: usize = 12;
const MAX_WEIGHT: usize = 32;
const MAX_PARSEABLE_INPUT_LENGTH: usize = 27;
const RATIO_SCALE: i64 = 1_000_000;
const MAX_SCALED_RATIO: i64 = 1_000_000_000;
const NEGATIVE_INFINITY: i64 = i64::MIN / 4;

fn ratio_feasible(numerators: &[i64; MAX_ITEMS], denominators: &[i64; MAX_ITEMS],
                  n: usize, required_weight: usize, threshold: i64) -> bool {
    let mut current = [NEGATIVE_INFINITY; MAX_WEIGHT + 1];
    let mut next = [NEGATIVE_INFINITY; MAX_WEIGHT + 1];
    current[0] = 0;
    for item in 0..n {
        for weight in 0..=required_weight {
            next[weight] = current[weight];
        }
        let score = RATIO_SCALE * numerators[item] - threshold * denominators[item];
        for weight in 0..=required_weight {
            if current[weight] == NEGATIVE_INFINITY { continue; }
            let sum_weight = weight + denominators[item] as usize;
            let target = sum_weight.min(required_weight);
            let candidate = current[weight] + score;
            if candidate > next[target] { next[target] = candidate; }
        }
        current = next;
    }
    current[required_weight] >= 0
}

#[no_mangle]
pub unsafe extern "C" fn fractional_programming_ratio_knapsack_binary_search(
    input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 2 || length > MAX_PARSEABLE_INPUT_LENGTH { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let n_value = values[0];
    let required_value = values[1];
    if !(1..=MAX_ITEMS as i64).contains(&n_value) || !(1..=MAX_WEIGHT as i64).contains(&required_value) {
        return -1;
    }
    let n = n_value as usize;
    let required_weight = required_value as usize;
    if length != 2 + 2 * n { return -1; }

    let mut numerators = [0_i64; MAX_ITEMS];
    let mut denominators = [0_i64; MAX_ITEMS];
    let mut denominator_sum = 0_i64;
    for item in 0..n {
        let numerator = values[2 + 2 * item];
        let denominator = values[3 + 2 * item];
        if !(0..=1000).contains(&numerator) || !(1..=8).contains(&denominator) { return -1; }
        numerators[item] = numerator;
        denominators[item] = denominator;
        denominator_sum += denominator;
    }
    if required_value > denominator_sum { return -1; }

    let mut low = 0_i64;
    let mut high = MAX_SCALED_RATIO + 1;
    while high - low > 1 {
        let middle = low + (high - low) / 2;
        if ratio_feasible(&numerators, &denominators, n, required_weight, middle) {
            low = middle;
        } else {
            high = middle;
        }
    }
    low
}
