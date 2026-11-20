fn middle_point(first: usize, second: usize) -> Option<usize> {
    if first == second {
        return None;
    }
    let first_x = (first % 3) as i32;
    let first_y = (first / 3) as i32;
    let second_x = (second % 3) as i32;
    let second_y = (second / 3) as i32;
    let delta_x = second_x - first_x;
    let delta_y = second_y - first_y;
    if delta_x % 2 != 0 || delta_y % 2 != 0 {
        return None;
    }
    let middle_x = (first_x + second_x) / 2;
    let middle_y = (first_y + second_y) / 2;
    let middle = (middle_y * 3 + middle_x) as usize;
    if middle == first || middle == second {
        None
    } else {
        Some(middle)
    }
}

fn count_from(last: usize, visited: u16, used: usize, target: usize) -> i64 {
    if used == target {
        return 1;
    }
    let mut count = 0_i64;
    for next in 0..9 {
        let bit = 1_u16 << next;
        if visited & bit != 0 {
            continue;
        }
        if let Some(middle) = middle_point(last, next) {
            if visited & (1_u16 << middle) == 0 {
                continue;
            }
        }
        count += count_from(next, visited | bit, used + 1, target);
    }
    count
}

fn solve(input: &[i64]) -> i64 {
    if input.len() != 1 || !(4..=9).contains(&input[0]) {
        return -1;
    }
    let target = input[0] as usize;
    let mut count = 0_i64;
    for start in 0..9 {
        count += count_from(start, 1_u16 << start, 1, target);
    }
    count
}

#[no_mangle]
pub unsafe extern "C" fn android_unlock_pattern_count(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length != 1 {
        return -1;
    }
    solve(std::slice::from_raw_parts(input, length))
}
