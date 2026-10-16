const MAX_STRING_LENGTH: usize = 32;
const MAX_INPUT_LENGTH: usize = 2 + 2 * MAX_STRING_LENGTH;
const SCALE: i64 = 1_000_000_000;

/// C#-faithful Jaro-Winkler distance in billionths, rounded to nearest (ties upward).
#[no_mangle]
pub unsafe extern "C" fn jaro_winkler_distance(input: *const i64, length: usize) -> i64 {
    if input.is_null() || !(2..=MAX_INPUT_LENGTH).contains(&length) {
        return -1;
    }
    let values = std::slice::from_raw_parts(input, length);
    let first_length_value = values[0];
    if !(0..=MAX_STRING_LENGTH as i64).contains(&first_length_value) {
        return -1;
    }
    let first_length = first_length_value as usize;
    let second_length_index = 1 + first_length;
    if second_length_index >= length {
        return -1;
    }
    let second_length_value = values[second_length_index];
    if !(0..=MAX_STRING_LENGTH as i64).contains(&second_length_value)
        || first_length_value < second_length_value
        || length != second_length_index + 1 + second_length_value as usize
    {
        return -1;
    }
    let second_length = second_length_value as usize;
    let first = &values[1..second_length_index];
    let second = &values[second_length_index + 1..];
    if first.iter().chain(second).any(|&value| !(0..=127).contains(&value)) {
        return -1;
    }
    if first == second {
        return 0;
    }
    if second_length == 0 {
        return SCALE;
    }

    let half = first_length / 2;
    let radius = if half > 0 { half - 1 } else { 0 };
    let mut first_matched = [false; MAX_STRING_LENGTH];
    let mut second_matched = [false; MAX_STRING_LENGTH];
    let mut match_count = 0usize;
    for i in 0..first_length {
        let start = if i > radius { i - radius } else { 0 };
        let end = (i + radius).min(second_length - 1);
        if start > end {
            continue;
        }
        for j in start..=end {
            if first[i] == second[j] && !second_matched[j] {
                first_matched[i] = true;
                second_matched[j] = true;
                match_count += 1;
                break;
            }
        }
    }
    if match_count == 0 {
        return SCALE;
    }

    let mut second_index = 0usize;
    let mut mismatched_pairs = 0usize;
    for i in 0..first_length {
        if !first_matched[i] {
            continue;
        }
        while second_index < second_length && !second_matched[second_index] {
            second_index += 1;
        }
        if second_index == second_length {
            return -1;
        }
        if first[i] != second[second_index] {
            mismatched_pairs += 1;
        }
        second_index += 1;
    }
    let matches = match_count as i64;
    let first_size = first_length as i64;
    let second_size = second_length as i64;
    let transpositions = (mismatched_pairs / 2) as i64;
    let jaro_numerator = matches * matches * second_size
        + matches * matches * first_size
        + (matches - transpositions) * first_size * second_size;
    let jaro_denominator = 3 * first_size * second_size * matches;

    let mut prefix_length = 0usize;
    let prefix_limit = second_length.min(4);
    while prefix_length < prefix_limit && first[prefix_length] == second[prefix_length] {
        prefix_length += 1;
    }
    let denominator = 10 * jaro_denominator;
    let numerator = (10 - prefix_length as i64) * (jaro_denominator - jaro_numerator);
    (numerator * SCALE + denominator / 2) / denominator
}
