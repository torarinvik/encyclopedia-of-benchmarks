fn rail_for_position(position: usize, rails: usize) -> usize {
    let period = 2 * (rails - 1);
    let phase = position % period;
    if phase < rails { phase } else { period - phase }
}

#[no_mangle]
pub unsafe extern "C" fn rail_fence(
    input: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if input.is_null() || !(3..=260).contains(&length) {
        return -1;
    }
    let values = std::slice::from_raw_parts(input, length);
    if !(0..=1).contains(&values[0]) || !(2..=8).contains(&values[1]) {
        return -1;
    }
    if !(0..=256).contains(&values[2]) {
        return -1;
    }
    let mode = values[0] as usize;
    let rails = values[1] as usize;
    let n = values[2] as usize;
    if length != n + 3 || values[3..].iter().any(|&byte| !(0..=127).contains(&byte)) {
        return -1;
    }
    if output.is_null() || capacity < n {
        return -2;
    }
    let result = std::slice::from_raw_parts_mut(output, n);

    if mode == 0 {
        let mut out = 0;
        for rail in 0..rails {
            for position in 0..n {
                if rail_for_position(position, rails) == rail {
                    result[out] = values[position + 3] as u8;
                    out += 1;
                }
            }
        }
    } else {
        let mut counts = [0usize; 8];
        let mut starts = [0usize; 8];
        let mut used = [0usize; 8];
        for position in 0..n {
            counts[rail_for_position(position, rails)] += 1;
        }
        for rail in 1..rails {
            starts[rail] = starts[rail - 1] + counts[rail - 1];
        }
        for position in 0..n {
            let rail = rail_for_position(position, rails);
            result[position] = values[3 + starts[rail] + used[rail]] as u8;
            used[rail] += 1;
        }
    }
    n as i64
}
