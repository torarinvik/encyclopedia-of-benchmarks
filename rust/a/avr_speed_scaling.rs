const MAX_JOBS: usize = 8;
const MAX_TIME: usize = 8;
const MAX_SEGMENTS: usize = 15;
const MAX_INPUT_LENGTH: usize = 25;
const MAX_OUTPUT_VALUES: usize = 79;
const DENSITY_SCALE: i64 = 840;

fn gcd_i64(mut left: i64, mut right: i64) -> i64 {
    while right != 0 {
        let remainder = left % right;
        left = right;
        right = remainder;
    }
    left
}

fn store_i64_le(output: &mut [u8], offset: usize, value: i64) {
    output[offset..offset + 8].copy_from_slice(&value.to_le_bytes());
}

#[no_mangle]
pub unsafe extern "C" fn avr_speed_scaling(
    input: *const i64,
    length: usize,
    output: *mut u8,
    output_capacity: usize,
) -> i64 {
    if input.is_null() || length < 2 || length > MAX_INPUT_LENGTH {
        return -1;
    }
    let values = unsafe { core::slice::from_raw_parts(input, length) };
    let count_value = values[0];
    if !(1..=MAX_JOBS as i64).contains(&count_value) {
        return -1;
    }
    let count = count_value as usize;
    if length != 1 + 3 * count {
        return -1;
    }

    let mut releases = [0usize; MAX_JOBS];
    let mut deadlines = [0usize; MAX_JOBS];
    let mut remaining = [0i64; MAX_JOBS];
    let mut finish_numerators = [0i64; MAX_JOBS];
    let mut finish_denominators = [0i64; MAX_JOBS];
    let mut changes = [0i64; MAX_TIME + 1];
    let mut endpoint = [false; MAX_TIME + 1];
    for job in 0..count {
        let offset = 1 + 3 * job;
        let release_value = values[offset];
        let deadline_value = values[offset + 1];
        let work_value = values[offset + 2];
        if release_value < 0
            || release_value >= deadline_value
            || deadline_value > MAX_TIME as i64
            || !(1..=8).contains(&work_value)
        {
            return -1;
        }
        let release = release_value as usize;
        let deadline = deadline_value as usize;
        let work = work_value;
        releases[job] = release;
        deadlines[job] = deadline;
        remaining[job] = work * DENSITY_SCALE;
        let scaled_density = work * (DENSITY_SCALE / (deadline - release) as i64);
        changes[release] += scaled_density;
        changes[deadline] -= scaled_density;
        endpoint[release] = true;
        endpoint[deadline] = true;
    }

    let mut speed_scaled = 0i64;
    let mut energy_scaled = 0i64;
    let mut segments = [[0i64; 4]; MAX_SEGMENTS];
    let mut segment_count = 0usize;
    for start in 0..MAX_TIME {
        speed_scaled += changes[start];
        if !endpoint[start] {
            continue;
        }
        let mut finish = start + 1;
        while finish <= MAX_TIME && !endpoint[finish] {
            finish += 1;
        }
        if finish > MAX_TIME || speed_scaled <= 0 {
            continue;
        }

        energy_scaled += speed_scaled * speed_scaled * speed_scaled * (finish - start) as i64;
        let speed_divisor = gcd_i64(speed_scaled, DENSITY_SCALE);
        let speed_numerator = speed_scaled / speed_divisor;
        let speed_denominator = DENSITY_SCALE / speed_divisor;
        if segment_count > 0
            && segments[segment_count - 1][1] == start as i64
            && segments[segment_count - 1][2] == speed_numerator
            && segments[segment_count - 1][3] == speed_denominator
        {
            segments[segment_count - 1][1] = finish as i64;
        } else {
            segments[segment_count] = [
                start as i64,
                finish as i64,
                speed_numerator,
                speed_denominator,
            ];
            segment_count += 1;
        }

        let mut cursor_scaled = start as i64 * speed_scaled;
        let end_scaled = finish as i64 * speed_scaled;
        while cursor_scaled < end_scaled {
            let mut selected: Option<usize> = None;
            for job in 0..count {
                if releases[job] <= start && start < deadlines[job] && remaining[job] > 0 {
                    let should_select = match selected {
                        None => true,
                        Some(best) => deadlines[job] < deadlines[best],
                    };
                    if should_select {
                        selected = Some(job);
                    }
                }
            }
            let Some(job) = selected else { break };
            let needed_scaled = remaining[job];
            if cursor_scaled + needed_scaled <= end_scaled {
                cursor_scaled += needed_scaled;
                remaining[job] = 0;
                let divisor = gcd_i64(cursor_scaled, speed_scaled);
                finish_numerators[job] = cursor_scaled / divisor;
                finish_denominators[job] = speed_scaled / divisor;
            } else {
                remaining[job] -= end_scaled - cursor_scaled;
                cursor_scaled = end_scaled;
            }
        }
    }

    let energy_denominator = DENSITY_SCALE * DENSITY_SCALE * DENSITY_SCALE;
    let energy_divisor = gcd_i64(energy_scaled, energy_denominator);
    let mut fields = [0i64; MAX_OUTPUT_VALUES];
    let mut field_count = 0usize;
    fields[field_count] = segment_count as i64;
    field_count += 1;
    fields[field_count] = energy_scaled / energy_divisor;
    field_count += 1;
    fields[field_count] = energy_denominator / energy_divisor;
    field_count += 1;
    for segment in 0..segment_count {
        for part in 0..4 {
            fields[field_count] = segments[segment][part];
            field_count += 1;
        }
    }
    for job in 0..count {
        if finish_denominators[job] <= 0 {
            return -1;
        }
        fields[field_count] = finish_numerators[job];
        field_count += 1;
        fields[field_count] = finish_denominators[job];
        field_count += 1;
    }

    let output_bytes = field_count * 8;
    if output.is_null() || output_capacity < output_bytes {
        return -2;
    }
    let output_slice = unsafe { core::slice::from_raw_parts_mut(output, output_bytes) };
    for field in 0..field_count {
        store_i64_le(output_slice, field * 8, fields[field]);
    }
    output_bytes as i64
}
