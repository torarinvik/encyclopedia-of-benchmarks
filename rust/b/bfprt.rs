const MAX_SIZE: usize = 1024;
const INVALID: i64 = -2_147_483_649;

fn swap_values(values: &mut [i32; MAX_SIZE], left: usize, right: usize) {
    values.swap(left, right);
}

fn insertion_sort(values: &mut [i32; MAX_SIZE], left: usize, right: usize) {
    for index in (left + 1)..=right {
        let mut cursor = index;
        while cursor > left && values[cursor - 1] > values[cursor] {
            swap_values(values, cursor - 1, cursor);
            cursor -= 1;
        }
    }
}

fn median_of_medians(values: &mut [i32; MAX_SIZE], left: usize, right: usize) -> i32 {
    let count = right - left + 1;
    let groups = (count + 4) / 5;
    for group in 0..groups {
        let group_left = left + group * 5;
        let group_right = right.min(group_left + 4);
        insertion_sort(values, group_left, group_right);
        let median = group_left + (group_right - group_left + 1) / 2;
        swap_values(values, left + group, median);
    }
    if groups == 1 {
        values[left]
    } else {
        select_bfprt(values, left, left + groups - 1, left + groups / 2)
    }
}

fn select_bfprt(values: &mut [i32; MAX_SIZE], mut left: usize, mut right: usize, rank: usize) -> i32 {
    while left < right {
        let pivot = median_of_medians(values, left, right);
        let mut less = left;
        let mut current = left;
        let mut greater = right + 1;
        while current < greater {
            if values[current] < pivot {
                swap_values(values, less, current);
                less += 1;
                current += 1;
            } else if values[current] > pivot {
                greater -= 1;
                swap_values(values, current, greater);
            } else {
                current += 1;
            }
        }
        if rank < less {
            right = less - 1;
        } else if rank >= greater {
            left = greater;
        } else {
            return values[rank];
        }
    }
    values[left]
}

#[no_mangle]
pub unsafe extern "C" fn bfprt(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 2 {
        return INVALID;
    }
    let input = std::slice::from_raw_parts(input, length);
    let count_value = input[0];
    let rank_value = input[1];
    if count_value < 1 || count_value > MAX_SIZE as i64 {
        return INVALID;
    }
    let count = count_value as usize;
    if length != count + 2 || rank_value < 1 || rank_value > count_value {
        return INVALID;
    }

    let mut values = [0_i32; MAX_SIZE];
    for index in 0..count {
        let value = input[index + 2];
        if value < i32::MIN as i64 || value > i32::MAX as i64 {
            return INVALID;
        }
        values[index] = value as i32;
    }
    i64::from(select_bfprt(&mut values, 0, count - 1, (rank_value - 1) as usize))
}
