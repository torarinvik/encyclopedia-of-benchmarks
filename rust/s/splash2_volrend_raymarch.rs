use std::slice;

const MAX_SIDE: usize = 8;
const MAX_RAYS: usize = 16;
const MAX_SAMPLES: usize = 32;
const MAX_VOXELS: usize = MAX_SIDE * MAX_SIDE * MAX_SIDE;
const MAX_PARSEABLE: usize = 3 + 2 * MAX_VOXELS + 6 * MAX_RAYS + 1;
const MAX_MASKS: usize = 4 * MAX_VOXELS;
const Q8: i64 = 256;
const Q16: i64 = 65_536;
const WEIGHT_DEN: i64 = 16_777_216;
const ALPHA_DEN: i64 = 255 * WEIGHT_DEN;
const COLOR_DEN: i64 = 255 * 255 * WEIGHT_DEN;

fn voxel_index(side: usize, x: usize, y: usize, z: usize) -> usize {
    (z * side + y) * side + x
}

fn mask_index(level: usize, x: usize, y: usize, z: usize) -> usize {
    ((level * MAX_SIDE + z) * MAX_SIDE + y) * MAX_SIDE + x
}

fn round_half_up(numerator: i64, denominator: i64) -> i64 {
    (numerator + denominator / 2) / denominator
}

fn to_byte(q16: i64) -> u8 {
    ((q16 * 255 + Q16 / 2) / Q16) as u8
}

fn interpolate(side: usize, alpha: &[u8; MAX_VOXELS], gray: &[u8; MAX_VOXELS],
               point: [i64; 3]) -> (i64, i64) {
    let low = [(point[0] / Q8) as usize, (point[1] / Q8) as usize, (point[2] / Q8) as usize];
    let frac = [(point[0] % Q8) as i64, (point[1] % Q8) as i64, (point[2] % Q8) as i64];
    let high = [
        (low[0] + 1).min(side - 1),
        (low[1] + 1).min(side - 1),
        (low[2] + 1).min(side - 1),
    ];
    let mut opacity_sum = 0_i64;
    let mut premul_sum = 0_i64;
    for dz in 0..2 {
        let z = if dz == 0 { low[2] } else { high[2] };
        let wz = if dz == 0 { Q8 - frac[2] } else { frac[2] };
        for dy in 0..2 {
            let y = if dy == 0 { low[1] } else { high[1] };
            let wy = if dy == 0 { Q8 - frac[1] } else { frac[1] };
            for dx in 0..2 {
                let x = if dx == 0 { low[0] } else { high[0] };
                let wx = if dx == 0 { Q8 - frac[0] } else { frac[0] };
                let at = voxel_index(side, x, y, z);
                let weight = wx * wy * wz;
                opacity_sum += alpha[at] as i64 * weight;
                premul_sum += alpha[at] as i64 * gray[at] as i64 * weight;
            }
        }
    }
    (
        round_half_up(opacity_sum * Q16, ALPHA_DEN),
        round_half_up(premul_sum * Q16, COLOR_DEN),
    )
}

#[no_mangle]
pub unsafe extern "C" fn splash2_volrend_raymarch(
    input_ptr: *const i64,
    length: usize,
    output_ptr: *mut u8,
    capacity: usize,
) -> i64 {
    if input_ptr.is_null() || length < 3 || length > MAX_PARSEABLE { return -1; }
    let input = slice::from_raw_parts(input_ptr, length);
    let side_raw = input[0];
    let ray_raw = input[1];
    let samples_raw = input[2];
    if ![2, 4, 8].contains(&side_raw) || ray_raw < 1 || ray_raw > MAX_RAYS as i64 ||
        samples_raw < 1 || samples_raw > MAX_SAMPLES as i64 { return -1; }
    let side = side_raw as usize;
    let ray_count = ray_raw as usize;
    let samples = samples_raw as usize;
    let voxel_count = side * side * side;
    let ray_start = 3 + 2 * voxel_count;
    if length != ray_start + 6 * ray_count { return -1; }

    let mut alpha = [0_u8; MAX_VOXELS];
    let mut gray = [0_u8; MAX_VOXELS];
    let mut rays = [[0_i32; 6]; MAX_RAYS];
    for voxel in 0..voxel_count {
        let a = input[3 + 2 * voxel];
        let g = input[4 + 2 * voxel];
        if !(0..=255).contains(&a) || !(0..=255).contains(&g) { return -1; }
        alpha[voxel] = a as u8;
        gray[voxel] = g as u8;
    }
    let coordinate_max = (side as i64 - 1) * Q8;
    for ray in 0..ray_count {
        let at = ray_start + 6 * ray;
        for axis in 0..3 {
            let origin = input[at + axis];
            let delta = input[at + axis + 3];
            if origin < 0 || origin > coordinate_max || delta < -coordinate_max || delta > coordinate_max { return -1; }
            rays[ray][axis] = origin as i32;
            rays[ray][axis + 3] = delta as i32;
        }
        if samples > 1 && rays[ray][3] == 0 && rays[ray][4] == 0 && rays[ray][5] == 0 { return -1; }
        for sample in 0..samples {
            for axis in 0..3 {
                let q = rays[ray][axis] as i64 + sample as i64 * rays[ray][axis + 3] as i64;
                if q < 0 || q > coordinate_max { return -1; }
            }
        }
    }

    let output_bytes = 5 * ray_count;
    if output_ptr.is_null() { return -2; }
    if capacity < output_bytes { return -3; }

    let mut support = [0_u8; MAX_MASKS];
    for z in 0..side {
        for y in 0..side {
            for x in 0..side {
                let mut occupied = 0_u8;
                for dz in 0..2 {
                    for dy in 0..2 {
                        for dx in 0..2 {
                            let nx = (x + dx).min(side - 1);
                            let ny = (y + dy).min(side - 1);
                            let nz = (z + dz).min(side - 1);
                            occupied |= u8::from(alpha[voxel_index(side, nx, ny, nz)] != 0);
                        }
                    }
                }
                support[mask_index(0, x, y, z)] = occupied;
            }
        }
    }
    let mut levels = 0;
    let mut dimension = side;
    while dimension > 1 { dimension >>= 1; levels += 1; }
    for level in 1..=levels {
        let dim = side >> level;
        for z in 0..dim { for y in 0..dim { for x in 0..dim {
            let mut occupied = 0_u8;
            for dz in 0..2 { for dy in 0..2 { for dx in 0..2 {
                occupied |= support[mask_index(level - 1, 2 * x + dx, 2 * y + dy, 2 * z + dz)];
            }}}
            support[mask_index(level, x, y, z)] = occupied;
        }}}
    }

    let output = slice::from_raw_parts_mut(output_ptr, output_bytes);
    for ray in 0..ray_count {
        let mut accumulated_alpha = 0_i64;
        let mut accumulated_gray = 0_i64;
        let mut used = 0;
        for sample in 0..samples {
            used = sample + 1;
            let point = [
                rays[ray][0] as i64 + sample as i64 * rays[ray][3] as i64,
                rays[ray][1] as i64 + sample as i64 * rays[ray][4] as i64,
                rays[ray][2] as i64 + sample as i64 * rays[ray][5] as i64,
            ];
            let cell = [(point[0] / Q8) as usize, (point[1] / Q8) as usize, (point[2] / Q8) as usize];
            let mut supported = true;
            for level in (0..=levels).rev() {
                if support[mask_index(level, cell[0] >> level, cell[1] >> level, cell[2] >> level)] == 0 {
                    supported = false;
                    break;
                }
            }
            if supported {
                let (sample_alpha, sample_gray) = interpolate(side, &alpha, &gray, point);
                let remaining = Q16 - accumulated_alpha;
                accumulated_alpha = (accumulated_alpha + round_half_up(remaining * sample_alpha, Q16)).min(Q16);
                accumulated_gray = (accumulated_gray + round_half_up(remaining * sample_gray, Q16)).min(Q16);
                if accumulated_alpha == Q16 { break; }
            }
        }
        let at = 5 * ray;
        let value = to_byte(accumulated_gray);
        output[at] = value;
        output[at + 1] = value;
        output[at + 2] = value;
        output[at + 3] = to_byte(accumulated_alpha);
        output[at + 4] = used as u8;
    }
    output_bytes as i64
}
