const MAX_MOLECULES: usize = 64;
const MAX_GRID_SIDE: usize = 8;
const MAX_CELLS: usize = 512;
const MAX_INPUT_LENGTH: usize = 4 + 4 * MAX_MOLECULES;
const SCALE: i64 = 1_000_000;

fn trunc_div(numerator: i64, denominator: i64) -> i64 {
    if numerator < 0 { -((-numerator) / denominator) } else { numerator / denominator }
}

fn store_i64_le(output: *mut u8, offset: usize, value: i64) {
    let bytes = value.to_le_bytes();
    unsafe { std::ptr::copy_nonoverlapping(bytes.as_ptr(), output.add(offset), 8); }
}

#[no_mangle]
pub unsafe extern "C" fn water_spatial(
    input: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if input.is_null() || length < 3 || length > MAX_INPUT_LENGTH { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let count_value = values[0];
    let grid_value = values[1];
    let cutoff = values[2];
    if count_value < 0 || count_value > MAX_MOLECULES as i64
            || grid_value < 1 || grid_value > MAX_GRID_SIDE as i64
            || cutoff < 1 || cutoff > 4 { return -1; }
    let count = count_value as usize;
    let grid = grid_value as usize;
    if length != 3 + 4 * count { return -1; }
    let extent = grid as i64 * cutoff;
    for index in 0..count {
        let base = 3 + 4 * index;
        if values[base] < 0 || values[base] >= extent
                || values[base + 1] < 0 || values[base + 1] >= extent
                || values[base + 2] < 0 || values[base + 2] >= extent
                || !(-4..=4).contains(&values[base + 3]) { return -1; }
    }
    let output_bytes = 8 * (3 * count + 2);
    if output.is_null() || capacity < output_bytes { return -2; }

    let mut head = [-1i64; MAX_CELLS];
    let mut next = [0i64; MAX_MOLECULES];
    let mut force_x = [0i64; MAX_MOLECULES];
    let mut force_y = [0i64; MAX_MOLECULES];
    let mut force_z = [0i64; MAX_MOLECULES];
    for index in 0..count {
        let base = 3 + 4 * index;
        let cx = (values[base] / cutoff) as usize;
        let cy = (values[base + 1] / cutoff) as usize;
        let cz = (values[base + 2] / cutoff) as usize;
        let cell = cx + grid * (cy + grid * cz);
        next[index] = head[cell];
        head[cell] = index as i64;
    }

    let mut energy = 0i64;
    let mut pairs = 0i64;
    let cutoff_squared = cutoff * cutoff;
    for index in 0..count {
        let base_i = 3 + 4 * index;
        let cx = (values[base_i] / cutoff) as i64;
        let cy = (values[base_i + 1] / cutoff) as i64;
        let cz = (values[base_i + 2] / cutoff) as i64;
        for oz in -1..=1 {
            let nz = cz + oz;
            if nz < 0 || nz >= grid as i64 { continue; }
            for oy in -1..=1 {
                let ny = cy + oy;
                if ny < 0 || ny >= grid as i64 { continue; }
                for ox in -1..=1 {
                    let nx = cx + ox;
                    if nx < 0 || nx >= grid as i64 { continue; }
                    let cell = nx as usize + grid * (ny as usize + grid * nz as usize);
                    let mut candidate = head[cell];
                    while candidate >= 0 {
                        let other = candidate as usize;
                        if other > index {
                            let base_j = 3 + 4 * other;
                            let dx = values[base_j] - values[base_i];
                            let dy = values[base_j + 1] - values[base_i + 1];
                            let dz = values[base_j + 2] - values[base_i + 2];
                            let r2 = dx * dx + dy * dy + dz * dz;
                            if r2 < cutoff_squared {
                                let product = values[base_i + 3] * values[base_j + 3];
                                energy += trunc_div(product * (cutoff_squared - r2) * SCALE,
                                                    (1 + r2) * (1 + cutoff_squared));
                                let denominator = (1 + r2) * (1 + r2);
                                let px = trunc_div(-2 * product * dx * SCALE, denominator);
                                let py = trunc_div(-2 * product * dy * SCALE, denominator);
                                let pz = trunc_div(-2 * product * dz * SCALE, denominator);
                                force_x[index] += px; force_x[other] -= px;
                                force_y[index] += py; force_y[other] -= py;
                                force_z[index] += pz; force_z[other] -= pz;
                                pairs += 1;
                            }
                        }
                        candidate = next[other];
                    }
                }
            }
        }
    }
    for index in 0..count {
        store_i64_le(output, 8 * (3 * index), force_x[index]);
        store_i64_le(output, 8 * (3 * index + 1), force_y[index]);
        store_i64_le(output, 8 * (3 * index + 2), force_z[index]);
    }
    store_i64_le(output, 8 * (3 * count), energy);
    store_i64_le(output, 8 * (3 * count + 1), pairs);
    output_bytes as i64
}
