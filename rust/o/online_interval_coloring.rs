// Clean-room bounded Kierstead-Trotter online interval coloring profile.
use core::ptr;

const MAX_N: usize = 64;
const MAX_INPUT: usize = 129;

fn store_i64_le(output: *mut u8, offset: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 { unsafe { ptr::write(output.add(offset + byte), (bits >> (8 * byte)) as u8); } }
}

fn level_fits(left: &[i64; MAX_N], right: &[i64; MAX_N], levels: &[usize; MAX_N],
              last: usize, candidate: usize) -> bool {
    for anchor in 0..=last {
        let point = left[anchor];
        let mut overlap = 0;
        for item in 0..=last {
            if (item == last || levels[item] <= candidate) && left[item] <= point && point <= right[item] { overlap += 1; }
        }
        if overlap > candidate { return false; }
    }
    true
}

#[no_mangle]
pub unsafe extern "C" fn online_interval_coloring(input: *const i64, length: usize,
    output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 1 || length > MAX_INPUT { return -1; }
    let count = *input;
    if count < 0 || count > MAX_N as i64 || length != 1 + 2 * count as usize { return -1; }
    let n = count as usize;
    let mut left = [0i64; MAX_N]; let mut right = [0i64; MAX_N];
    for i in 0..n {
        left[i] = *input.add(1 + 2 * i); right[i] = *input.add(2 + 2 * i);
        if left[i] < -1000 || left[i] > 1000 || right[i] < -1000 || right[i] > 1000 || left[i] > right[i] { return -1; }
    }
    let output_bytes = 8 * n;
    if output.is_null() || capacity < output_bytes { return -2; }
    let mut levels = [0usize; MAX_N]; let mut local = [0usize; MAX_N]; let mut colors = [0usize; MAX_N];
    for i in 0..n {
        let mut level = 1;
        while !level_fits(&left, &right, &levels, i, level) {
            level += 1;
            if level > i + 1 { return -1; }
        }
        levels[i] = level;
        let mut used = [false; 3];
        for j in 0..i {
            if levels[j] == level && left[j] <= right[i] && left[i] <= right[j] && local[j] < 3 { used[local[j]] = true; }
        }
        let mut color = 0;
        while color < 3 && used[color] { color += 1; }
        if color == 3 { return -1; }
        local[i] = color; colors[i] = 3 * (level - 1) + color;
    }
    for i in 0..n { store_i64_le(output, 8 * i, colors[i] as i64); }
    output_bytes as i64
}
