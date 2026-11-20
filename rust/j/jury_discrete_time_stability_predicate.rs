const MAX_DEGREE: i64 = 4;
const MAX_PARSEABLE_LENGTH: usize = 7;

#[no_mangle]
pub unsafe extern "C" fn jury_discrete_time_stability_predicate(
    input: *const i64,
    length: usize,
) -> i64 {
    if input.is_null() || !(1..=MAX_PARSEABLE_LENGTH).contains(&length) {
        return -1;
    }
    let degree = unsafe { *input };
    if !(1..=MAX_DEGREE).contains(&degree) || length != degree as usize + 2 {
        return -1;
    }

    let mut coefficients = [0i64; 5];
    for index in 0..=degree as usize {
        let value = unsafe { *input.add(index + 1) };
        if !(-9..=9).contains(&value) || (index == 0 && value == 0) {
            return -1;
        }
        coefficients[index] = value;
    }
    if coefficients[0] < 0 {
        for coefficient in &mut coefficients[..=degree as usize] {
            *coefficient = -*coefficient;
        }
    }

    let mut at_one = 0i64;
    let mut at_minus_one = 0i64;
    for (index, &coefficient) in coefficients[..=degree as usize].iter().enumerate() {
        at_one += coefficient;
        if (degree as usize - index) % 2 == 0 {
            at_minus_one += coefficient;
        } else {
            at_minus_one -= coefficient;
        }
    }
    if at_one <= 0 || ((degree % 2 == 0 && at_minus_one <= 0)
        || (degree % 2 != 0 && at_minus_one >= 0)) {
        return 0;
    }

    let mut row = coefficients;
    let mut reduced = [0i64; 5];
    for current_degree in (1..=degree as usize).rev() {
        let trailing = row[current_degree];
        let trailing_magnitude = if trailing < 0 { -trailing } else { trailing };
        if row[0] <= trailing_magnitude {
            return 0;
        }
        if current_degree == 1 {
            break;
        }
        for index in 0..current_degree {
            reduced[index] = row[0] * row[index] - trailing * row[current_degree - index];
        }
        row[..current_degree].copy_from_slice(&reduced[..current_degree]);
    }
    1
}
