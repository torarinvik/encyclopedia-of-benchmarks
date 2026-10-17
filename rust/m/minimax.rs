const MAX_LEAVES: usize = 32;
const MAX_INPUT_LENGTH: usize = 2 + MAX_LEAVES;
const INVALID_RESULT: i64 = -2_147_483_649;

fn evaluate(values: &[i64], index: usize, depth: usize, height: usize, maximizing: bool) -> i64 {
    if depth == height { return values[2 + index]; }
    let left = evaluate(values, index * 2, depth + 1, height, !maximizing);
    let right = evaluate(values, index * 2 + 1, depth + 1, height, !maximizing);
    if maximizing { left.max(right) } else { left.min(right) }
}

#[no_mangle]
pub extern "C" fn minimax(values: *const i64, length: usize) -> i64 {
    if values.is_null() || length < 2 || length > MAX_INPUT_LENGTH { return INVALID_RESULT; }
    let values = unsafe { std::slice::from_raw_parts(values, length) };
    let leaf_count = values[0];
    let first_turn_is_max = values[1];
    if !(1..=MAX_LEAVES as i64).contains(&leaf_count)
        || (leaf_count & (leaf_count - 1)) != 0
        || !(0..=1).contains(&first_turn_is_max)
        || length != 2 + leaf_count as usize { return INVALID_RESULT; }
    if values[2..].iter().any(|&score| score < i32::MIN as i64 || score > i32::MAX as i64) {
        return INVALID_RESULT;
    }
    let leaf_count = leaf_count as usize;
    let height = leaf_count.trailing_zeros() as usize;
    evaluate(values, 0, 0, height, first_turn_is_max == 1)
}
