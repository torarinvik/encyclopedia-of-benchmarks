const MAX_PARTICLES: usize = 32;
const MAX_INPUT_LENGTH: usize = 2 + 6 * MAX_PARTICLES;
const PI: f64 = 3.14159265358979323846264338327950288;

fn store_f64_le(output: &mut [u8], offset: usize, value: f64) {
    output[offset..offset + 8].copy_from_slice(&value.to_le_bytes());
}

#[no_mangle]
pub unsafe extern "C" fn fluidanimate_sph(
    input: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if input.is_null() || length < 2 || length > MAX_INPUT_LENGTH { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let count_value = values[0];
    let rpm_milli = values[1];
    if count_value < 1 || count_value > MAX_PARTICLES as i64
            || rpm_milli < 500 || rpm_milli > 5000 { return -1; }
    let count = count_value as usize;
    if length != 2 + 6 * count { return -1; }
    for i in 0..count {
        let base = 2 + 6 * i;
        if values[base..base + 3].iter().any(|&x| !(-10000..=10000).contains(&x))
                || values[base + 3..base + 6].iter().any(|&x| !(-5000..=5000).contains(&x)) {
            return -1;
        }
    }
    let output_bytes = 40 * count;
    if output.is_null() || capacity < output_bytes { return -2; }
    let result = std::slice::from_raw_parts_mut(output, output_bytes);

    let mut position = [[0.0f64; 3]; MAX_PARTICLES];
    let mut velocity = [[0.0f64; 3]; MAX_PARTICLES];
    let mut acceleration = [[0.0f64; 3]; MAX_PARTICLES];
    let mut density = [0.0f64; MAX_PARTICLES];
    let rpm = rpm_milli as f64 / 1000.0;
    let h = 1.695 / rpm;
    let h2 = h * h;
    let mass = 1000.0 / (rpm * rpm * rpm);
    let density_coeff = mass * (315.0 / (64.0 * PI * h.powi(9)));
    let pressure_coeff = 3.0 * (15.0 / (PI * h.powi(6))) * 1.5 * mass;
    let viscosity_coeff = 0.4 * (45.0 / (PI * h.powi(6))) * mass;
    for i in 0..count {
        let base = 2 + 6 * i;
        for axis in 0..3 {
            position[i][axis] = values[base + axis] as f64 / 1000.0;
            velocity[i][axis] = values[base + 3 + axis] as f64 / 1000.0;
            acceleration[i][axis] = if axis == 1 { -9.8 } else { 0.0 };
        }
        density[i] = density_coeff * h2 * h2 * h2;
    }
    for i in 0..count {
        for j in i + 1..count {
            let dx = position[i][0] - position[j][0];
            let dy = position[i][1] - position[j][1];
            let dz = position[i][2] - position[j][2];
            let r2 = dx * dx + dy * dy + dz * dz;
            if r2 < h2 {
                let t = h2 - r2;
                let term = density_coeff * t * t * t;
                density[i] += term;
                density[j] += term;
            }
        }
    }
    for i in 0..count {
        for j in i + 1..count {
            let disp = [
                position[i][0] - position[j][0],
                position[i][1] - position[j][1],
                position[i][2] - position[j][2],
            ];
            let r2 = disp[0] * disp[0] + disp[1] * disp[1] + disp[2] * disp[2];
            if r2 >= h2 { continue; }
            let distance = r2.max(1e-12).sqrt();
            let hmr = h - distance;
            let rho_product = density[i] * density[j];
            let pressure_scale = pressure_coeff * (hmr * hmr / distance)
                * (density[i] + density[j] - 2000.0) / rho_product;
            let viscosity_scale = viscosity_coeff * hmr / rho_product;
            for axis in 0..3 {
                let force = disp[axis] * pressure_scale
                    + (velocity[j][axis] - velocity[i][axis]) * viscosity_scale;
                acceleration[i][axis] += force;
                acceleration[j][axis] -= force;
            }
        }
    }
    for i in 0..count {
        let fields = [density[i], 3.0 * (density[i] - 1000.0),
            acceleration[i][0], acceleration[i][1], acceleration[i][2]];
        for field in 0..5 { store_f64_le(result, 8 * (5 * i + field), fields[field]); }
    }
    output_bytes as i64
}
