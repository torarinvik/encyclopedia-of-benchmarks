const MAX_VALUES: usize = 64;
const MAX_INPUT_LENGTH: usize = MAX_VALUES + 3;
const SAMPLE_CUTOFF: usize = 24;

fn select_kth(values: &mut [i64; MAX_VALUES], initial_left: usize, initial_right: usize, target: usize) -> i64 {
    let (mut left, mut right) = (initial_left, initial_right);
    loop {
        if right - left > SAMPLE_CUTOFF {
            let size = right - left + 1;
            let relative_rank = target - left + 1;
            let size_f = size as f64;
            let rank_f = relative_rank as f64;
            let z = size_f.ln().sqrt();
            let sample_size = 0.5 * (2.0 * z / 3.0).exp();
            let direction = if rank_f < size_f / 2.0 { -1.0 }
                else if rank_f > size_f / 2.0 { 1.0 }
                else { 0.0 };
            let spread = 0.5 * (z * sample_size * (size_f - sample_size) / size_f).sqrt() * direction;
            let lower_estimate = target as f64 - rank_f * sample_size / size_f + spread;
            let upper_estimate = target as f64 + (size_f - rank_f) * sample_size / size_f + spread;
            let sample_left = (lower_estimate.floor() as isize)
                .max(left as isize)
                .min(target as isize) as usize;
            let sample_right = (upper_estimate.ceil() as isize)
                .max(target as isize)
                .min(right as isize) as usize;
            let _ = select_kth(values, sample_left, sample_right, target);
        }

        let pivot = values[target];
        let (mut less, mut scan, mut greater) = (left, left, right);
        while scan <= greater {
            if values[scan] < pivot {
                values.swap(less, scan);
                less += 1;
                scan += 1;
            } else if values[scan] > pivot {
                values.swap(scan, greater);
                greater -= 1;
            } else {
                scan += 1;
            }
        }
        if target < less {
            right = less - 1;
        } else if target > greater {
            left = greater + 1;
        } else {
            return pivot;
        }
    }
}

#[no_mangle]
pub unsafe extern "C" fn floyd_rivest_select(input: *const i64, length: usize) -> i64 {
    if input.is_null() || !(3..=MAX_INPUT_LENGTH).contains(&length) {
        return -1;
    }
    let input = std::slice::from_raw_parts(input, length);
    let (count_value, rank_value) = (input[0], input[1]);
    if !(1..=MAX_VALUES as i64).contains(&count_value)
        || rank_value < 0
        || rank_value >= count_value
        || length != count_value as usize + 2
    {
        return -1;
    }

    let count = count_value as usize;
    let mut values = [0_i64; MAX_VALUES];
    for index in 0..count {
        let value = input[index + 2];
        if !(0..=2_147_483_647).contains(&value) || values[..index].contains(&value) {
            return -1;
        }
        values[index] = value;
    }
    select_kth(&mut values, 0, count - 1, rank_value as usize)
}
