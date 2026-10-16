const INVALID_RESULT: f64 = -1.0e300;
const MIN_PROPORTION: f64 = 1.0e-5;
const MAX_PROPORTION: f64 = 1.0;
const MAX_PARTITIONS: i64 = 5_000_000;

fn is_power_of_two(value: i64) -> bool {
    value > 0 && (value & (value - 1)) == 0
}

#[no_mangle]
pub extern "C" fn problem207(max_proportion: f64) -> f64 {
    if max_proportion.is_nan() || max_proportion < MIN_PROPORTION || max_proportion > MAX_PROPORTION {
        return INVALID_RESULT;
    }
    let mut partitions = 0i64;
    let mut perfect_partitions = 0i64;
    while partitions < MAX_PARTITIONS {
        partitions += 1;
        let candidate = partitions * (partitions + 1);
        if is_power_of_two(partitions + 1) { perfect_partitions += 1; }
        if (perfect_partitions as f64) / (partitions as f64) < max_proportion {
            return candidate as f64;
        }
    }
    INVALID_RESULT
}
