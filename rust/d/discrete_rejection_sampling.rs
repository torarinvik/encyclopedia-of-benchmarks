const MAX_CATEGORIES: usize = 8;
const MAX_SAMPLES: usize = 8;
const MAX_ATTEMPTS: usize = 32;
const MAX_INPUT_VALUES: usize = 83;
const DRAW_SCALE: u64 = 1u64 << 32;

unsafe fn store_i64_le(output: *mut u8, offset: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 {
        *output.add(offset + byte) = (bits >> (8 * byte)) as u8;
    }
}

#[no_mangle]
pub unsafe extern "C" fn discrete_rejection_sampling(
    input: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if input.is_null() || length < 3 || length > MAX_INPUT_VALUES {
        return -1;
    }
    let values = std::slice::from_raw_parts(input, length);
    let (n_value, samples_value, attempts_value) = (values[0], values[1], values[2]);
    if !(1..=MAX_CATEGORIES as i64).contains(&n_value)
        || !(1..=MAX_SAMPLES as i64).contains(&samples_value)
        || !(1..=MAX_ATTEMPTS as i64).contains(&attempts_value)
    {
        return -1;
    }
    let n = n_value as usize;
    let wanted = samples_value as usize;
    let attempts = attempts_value as usize;
    if length != 3 + 2 * n + 2 * attempts {
        return -1;
    }

    let mut target = [0u64; MAX_CATEGORIES];
    let mut proposal = [0u64; MAX_CATEGORIES];
    let mut cumulative = [0u64; MAX_CATEGORIES];
    let mut target_total = 0u64;
    let mut proposal_total = 0u64;
    for i in 0..n {
        let weight = values[3 + i];
        let q_weight = values[3 + n + i];
        if !(1..=20).contains(&weight) || !(1..=20).contains(&q_weight) {
            return -1;
        }
        target[i] = weight as u64;
        proposal[i] = q_weight as u64;
        target_total += target[i];
        proposal_total += proposal[i];
        cumulative[i] = proposal_total;
    }

    let mut envelope = 1u64;
    for i in 0..n {
        let numerator = target[i] * proposal_total;
        let denominator = target_total * proposal[i];
        let ratio_ceiling = (numerator + denominator - 1) / denominator;
        envelope = envelope.max(ratio_ceiling);
    }

    let tape_offset = 3 + 2 * n;
    for attempt in 0..attempts {
        let proposal_draw = values[tape_offset + 2 * attempt];
        let acceptance_draw = values[tape_offset + 2 * attempt + 1];
        if proposal_draw < 0 || proposal_draw as u64 >= proposal_total
            || acceptance_draw < 0 || acceptance_draw as u64 >= DRAW_SCALE
        {
            return -1;
        }
    }

    let output_bytes = 16 * wanted;
    if output.is_null() || capacity < output_bytes {
        return -2;
    }
    let mut staged = [0i64; 2 * MAX_SAMPLES];
    let mut produced = 0usize;
    let mut attempts_since_acceptance = 0usize;
    for attempt in 0..attempts {
        attempts_since_acceptance += 1;
        let proposal_draw = values[tape_offset + 2 * attempt] as u64;
        let acceptance_draw = values[tape_offset + 2 * attempt + 1] as u64;
        let category = cumulative[..n].partition_point(|&end| end <= proposal_draw);
        let left = acceptance_draw * target_total * proposal[category] * envelope;
        let right = DRAW_SCALE * target[category] * proposal_total;
        if left < right {
            staged[produced] = category as i64;
            staged[produced + 1] = attempts_since_acceptance as i64;
            produced += 2;
            attempts_since_acceptance = 0;
            if produced == 2 * wanted {
                break;
            }
        }
    }
    if produced != 2 * wanted {
        return -3;
    }
    for i in 0..produced {
        store_i64_le(output, 8 * i, staged[i]);
    }
    output_bytes as i64
}
