const MAX_ITEMS: usize = 32;
const MAX_TARGET: i64 = 256;
const MAX_WEIGHT: i64 = 12;
const MAX_PARSEABLE_INPUT_LENGTH: usize = 35;

#[no_mangle]
pub unsafe extern "C" fn pisinger_bounded_weight_subset_sum(
    input: *const i64,
    length: usize,
) -> i64 {
    if input.is_null() || length < 2 || length > MAX_PARSEABLE_INPUT_LENGTH {
        return -1;
    }
    let values = unsafe { core::slice::from_raw_parts(input, length) };
    let n_value = values[0];
    let target_value = values[1];
    if n_value < 0 || n_value > MAX_ITEMS as i64 || target_value < 0 || target_value > MAX_TARGET {
        return -1;
    }
    let n = n_value as usize;
    if length != n + 2 {
        return -1;
    }

    let weights = &values[2..];
    let mut width = 0_i32;
    for &weight in weights {
        if !(1..=MAX_WEIGHT).contains(&weight) {
            return -1;
        }
        width = width.max(weight as i32);
    }
    if n == 0 {
        return 0;
    }

    let target = target_value as i32;
    let mut prefix_sum = 0_i32;
    let mut break_index = 0_usize;
    while break_index < n && prefix_sum + weights[break_index] as i32 <= target {
        prefix_sum += weights[break_index] as i32;
        break_index += 1;
    }
    if break_index == n {
        return i64::from(prefix_sum);
    }

    let mut previous = [-1_i32; 2 * MAX_WEIGHT as usize];
    let mut current = [-1_i32; 2 * MAX_WEIGHT as usize];
    previous[(prefix_sum + width - target - 1) as usize] = break_index as i32;

    for item in break_index..n {
        current[..(2 * width) as usize].copy_from_slice(&previous[..(2 * width) as usize]);
        let weight = weights[item] as i32;
        for slot in 0..width {
            let destination = slot + weight;
            current[destination as usize] = current[destination as usize].max(previous[slot as usize]);
        }
        for slot in (width as usize..(2 * width) as usize).rev() {
            let first_item = previous[slot as usize].max(0);
            let stop_item = current[slot as usize];
            for removed in first_item..stop_item {
                let removed_index = removed as usize;
                let reduced = slot - weights[removed_index] as i32;
                current[reduced as usize] = current[reduced as usize].max(removed);
            }
        }
        core::mem::swap(&mut previous, &mut current);
    }

    let low_mass = if target >= width { target - width + 1 } else { 0 };
    let mut mass = target;
    while mass >= low_mass {
        if previous[(mass + width - target - 1) as usize] >= 0 {
            return i64::from(mass);
        }
        if mass == low_mass {
            break;
        }
        mass -= 1;
    }
    0
}
