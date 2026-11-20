const MAX_DEGREE: i64 = 4;
const MAX_PARSEABLE_LENGTH: usize = 7;

#[no_mangle]
pub unsafe extern "C" fn routh_hurwitz_stability_predicate(
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
        if !(-3..=3).contains(&value) || (index == 0 && value <= 0) {
            return -1;
        }
        coefficients[index] = value;
    }

    let width = (degree as usize + 2) / 2;
    let mut table = [[0i64; 3]; 5];
    for column in 0..width {
        let even_index = 2 * column;
        let odd_index = even_index + 1;
        if even_index <= degree as usize {
            table[0][column] = coefficients[even_index];
        }
        if odd_index <= degree as usize {
            table[1][column] = coefficients[odd_index];
        }
    }
    if table[1][..width].iter().all(|&value| value == 0) || table[1][0] <= 0 {
        return 0;
    }

    for row in 2..=degree as usize {
        if table[row - 1][0] <= 0 {
            return 0;
        }
        let mut all_zero = true;
        for column in 0..width {
            let upper_next = if column + 1 < width { table[row - 2][column + 1] } else { 0 };
            let lower_next = if column + 1 < width { table[row - 1][column + 1] } else { 0 };
            table[row][column] = table[row - 1][0] * upper_next
                              - table[row - 2][0] * lower_next;
            all_zero &= table[row][column] == 0;
        }
        if all_zero || table[row][0] <= 0 {
            return 0;
        }
    }
    1
}
