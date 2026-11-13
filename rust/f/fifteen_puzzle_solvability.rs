#[no_mangle]
pub unsafe extern "C" fn fifteen_puzzle_solvability(
    input: *const i64,
    length: usize,
) -> i64 {
    if input.is_null() || length != 16 {
        return -1;
    }
    let values = std::slice::from_raw_parts(input, length);

    let mut blank = -1_i64;
    for i in 0..16 {
        let value = values[i];
        if !(0..16).contains(&value) {
            return -1;
        }
        for j in 0..i {
            if value == values[j] {
                return -1;
            }
        }
        if value == 0 {
            blank = i as i64;
        }
    }
    if blank < 0 {
        return -1;
    }

    let mut inversions = 0_i64;
    for i in 0..16 {
        if values[i] == 0 {
            continue;
        }
        for j in (i + 1)..16 {
            if values[j] != 0 && values[i] > values[j] {
                inversions += 1;
            }
        }
    }
    let blank_row_from_top = blank / 4 + 1;
    if (inversions + blank_row_from_top) % 2 == 0 { 1 } else { 0 }
}
