const MAX_D: usize = 4;
const MAX_N: usize = 16;
const MAX_L: usize = 4;
const MAX_INPUT: usize = 318;
const Q24: i64 = 16_777_216;

fn round_away(numerator: i64, denominator: i64) -> i64 {
    let magnitude = numerator.abs();
    let mut quotient = magnitude / denominator;
    let remainder = magnitude % denominator;
    if 2 * remainder >= denominator { quotient += 1; }
    if numerator < 0 { -quotient } else { quotient }
}

fn store_i64_le(output: &mut [u8], offset: usize, value: i64) {
    output[offset..offset + 8].copy_from_slice(&value.to_le_bytes());
}

#[no_mangle]
pub unsafe extern "C" fn bodytrack_annealed_particle_filter(
    input: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if input.is_null() || length < 3 || length > MAX_INPUT { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let (d_raw, n_raw, layers_raw) = (values[0], values[1], values[2]);
    if !(1..=MAX_D as i64).contains(&d_raw)
        || !(2..=MAX_N as i64).contains(&n_raw)
        || !(1..=MAX_L as i64).contains(&layers_raw) { return -1; }
    let (d, n, layers) = (d_raw as usize, n_raw as usize, layers_raw as usize);
    let expected = 2 + d + 2 * layers + n * d + (layers - 1) * n * (d + 1);
    if length != expected { return -1; }

    let target_at = 3;
    let beta_at = target_at + d;
    let sigma_at = beta_at + layers;
    let pose_at = sigma_at + layers - 1;
    let uniform_at = pose_at + n * d;
    let shock_at = uniform_at + (layers - 1) * n;
    let target = &values[target_at..beta_at];
    let beta = &values[beta_at..sigma_at];
    let sigma = &values[sigma_at..pose_at];
    if target.iter().any(|&x| !(-10000..=10000).contains(&x))
        || beta.iter().any(|&x| !(1..=8).contains(&x))
        || beta.windows(2).any(|pair| pair[0] >= pair[1])
        || sigma.iter().any(|&x| !(0..=2000).contains(&x))
        || sigma.windows(2).any(|pair| pair[0] < pair[1])
        || values[pose_at..uniform_at].iter().any(|&x| !(-10000..=10000).contains(&x))
        || values[uniform_at..shock_at].iter().any(|&x| !(0..Q24).contains(&x))
        || values[shock_at..].iter().any(|&x| !(-3000..=3000).contains(&x)) { return -1; }

    let required = 8 * d;
    if output.is_null() || capacity < required { return -2; }
    let mut particles = [[[0i64; MAX_D]; MAX_N]; 2];
    let mut weights = [0i64; MAX_N];
    for particle in 0..n {
        for axis in 0..d {
            particles[0][particle][axis] = values[pose_at + particle * d + axis];
        }
    }
    let mut active = 0usize;
    let mut estimate = [0i64; MAX_D];
    for layer in 0..layers {
        let mut total_weight = 0i64;
        for particle in 0..n {
            let mut squared_distance = 0i64;
            for axis in 0..d {
                let delta = particles[active][particle][axis] - target[axis];
                squared_distance += delta * delta;
            }
            let energy = squared_distance / 10000;
            let base = Q24 * 100000 / (100000 + energy);
            let mut weight = base;
            for _ in 1..beta[layer] { weight = weight * base / Q24; }
            weights[particle] = weight;
            total_weight += weight;
        }
        if layer + 1 == layers {
            for axis in 0..d {
                let moment = (0..n).map(|i| weights[i] * particles[active][i][axis]).sum();
                estimate[axis] = round_away(moment, total_weight);
            }
            break;
        }
        let destination = 1 - active;
        for child in 0..n {
            let draw = values[uniform_at + layer * n + child];
            let threshold = draw * total_weight / Q24;
            let mut cumulative = 0i64;
            let mut ancestor = 0usize;
            while cumulative <= threshold {
                cumulative += weights[ancestor];
                ancestor += 1;
            }
            ancestor -= 1;
            for axis in 0..d {
                let shock = values[shock_at + layer * n * d + child * d + axis];
                let movement = round_away(sigma[layer] * shock, 1000);
                let coordinate = particles[active][ancestor][axis] + movement;
                particles[destination][child][axis] = coordinate.clamp(-10000, 10000);
            }
        }
        active = destination;
    }
    let output_bytes = std::slice::from_raw_parts_mut(output, required);
    for axis in 0..d { store_i64_le(output_bytes, 8 * axis, estimate[axis]); }
    required as i64
}
