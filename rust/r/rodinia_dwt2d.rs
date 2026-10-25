// Rodinia DWT2D (Jiri Matela, Martin Jirman); complete notices in
// benchmarks/r/rodinia_dwt2d/LICENSE.txt. Independent scalar 5/3 lifting port.
const MAX_SIDE: usize = 16;
const MAX_CELLS: usize = MAX_SIDE * MAX_SIDE;
const MAX_INPUT: usize = 3 + MAX_CELLS;

fn div_trunc(numerator: i64, denominator: i64) -> i64 {
    if numerator < 0 { -((-numerator) / denominator) } else { numerator / denominator }
}

fn transform_line(line: &[i64; MAX_SIDE], n: usize) -> [i64; MAX_SIDE] {
    let mut result = [0_i64; MAX_SIDE];
    let mut detail = [0_i64; MAX_SIDE / 2];
    let half = n / 2;
    for j in 0..half {
        let even = line[2 * j];
        let right = if j + 1 < half { line[2 * j + 2] } else { even };
        detail[j] = line[2 * j + 1] - div_trunc(even + right, 2);
    }
    result[0] = line[0] + div_trunc(detail[0] + detail[0] + 2, 4);
    for j in 1..half {
        result[j] = line[2 * j] + div_trunc(detail[j - 1] + detail[j] + 2, 4);
    }
    for j in 0..half { result[half + j] = detail[j]; }
    result
}

fn put_i32_le(output: *mut u8, offset: usize, value: i64) {
    let bits = (value as i32) as u32;
    for byte in 0..4 {
        unsafe { *output.add(offset + byte) = (bits >> (8 * byte)) as u8; }
    }
}

#[no_mangle]
pub unsafe extern "C" fn rodinia_dwt2d(values: *const i64, length: usize,
        output: *mut u8, capacity: usize) -> i64 {
    if values.is_null() || length < 3 || length > MAX_INPUT { return -1; }
    let v = unsafe { std::slice::from_raw_parts(values, length) };
    let (wi, hi, li) = (v[0], v[1], v[2]);
    if !(2..=16).contains(&wi) || !(2..=16).contains(&hi) || !(1..=3).contains(&li) { return -1; }
    let factor = 1_i64 << li;
    if wi < factor || hi < factor || wi % factor != 0 || hi % factor != 0 { return -1; }
    let width = wi as usize;
    let height = hi as usize;
    let cells = width * height;
    if length != 3 + cells || v[3..].iter().any(|&x| !(0..=255).contains(&x)) { return -1; }
    let output_bytes = cells * 4;
    if output.is_null() || capacity < output_bytes { return -2; }

    let mut plane = [0_i64; MAX_CELLS];
    let mut vertical = [0_i64; MAX_CELLS];
    let mut next = [0_i64; MAX_CELLS];
    let mut ordered = [0_i64; MAX_CELLS];
    for i in 0..cells { plane[i] = v[3 + i] - 128; }
    let (mut active_width, mut active_height) = (width, height);
    for _ in 0..li {
        for x in 0..active_width {
            let mut line = [0_i64; MAX_SIDE];
            for y in 0..active_height { line[y] = plane[y * width + x]; }
            let transformed = transform_line(&line, active_height);
            for y in 0..active_height { vertical[y * width + x] = transformed[y]; }
        }
        for y in 0..active_height {
            let mut line = [0_i64; MAX_SIDE];
            for x in 0..active_width { line[x] = vertical[y * width + x]; }
            let transformed = transform_line(&line, active_width);
            for x in 0..active_width { next[y * width + x] = transformed[x]; }
        }
        for y in 0..active_height {
            for x in 0..active_width { plane[y * width + x] = next[y * width + x]; }
        }
        active_width /= 2;
        active_height /= 2;
    }
    let mut output_index = 0;
    for stage in (0..li as usize).rev() {
        let stage_width = width >> stage;
        let stage_height = height >> stage;
        let half_width = stage_width / 2;
        let half_height = stage_height / 2;
        if stage == li as usize - 1 {
            for y in 0..half_height {
                for x in 0..half_width { ordered[output_index] = plane[y * width + x]; output_index += 1; }
            }
        }
        for y in 0..half_height {
            for x in half_width..stage_width { ordered[output_index] = plane[y * width + x]; output_index += 1; }
        }
        for y in half_height..stage_height {
            for x in 0..half_width { ordered[output_index] = plane[y * width + x]; output_index += 1; }
        }
        for y in half_height..stage_height {
            for x in half_width..stage_width { ordered[output_index] = plane[y * width + x]; output_index += 1; }
        }
    }
    for i in 0..cells { put_i32_le(output, 4 * i, ordered[i]); }
    output_bytes as i64
}
