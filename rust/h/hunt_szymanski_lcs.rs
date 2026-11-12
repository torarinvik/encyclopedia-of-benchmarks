/// Return the LCS length from matching positions and a minimum-tail LIS frontier.
#[no_mangle]
pub extern "C" fn hunt_szymanski_lcs(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 2 || length > 131 {
        return -1;
    }
    let input = unsafe { std::slice::from_raw_parts(input, length) };
    let n_value = input[0];
    let m_value = input[1];
    if !(0..=64).contains(&n_value)
        || !(0..=64).contains(&m_value)
        || length != 2 + n_value as usize + m_value as usize
    {
        return -1;
    }
    let n = n_value as usize;
    let m = m_value as usize;
    let symbols = &input[2..];
    if symbols.iter().any(|&value| !(0..=127).contains(&value)) {
        return -1;
    }

    let mut right_positions = [[0i32; 64]; 128];
    let mut position_count = [0i32; 128];
    let tails = &mut [0i32; 64];
    for j in 0..m {
        let symbol = symbols[n + j] as usize;
        let count = position_count[symbol] as usize;
        right_positions[symbol][count] = j as i32;
        position_count[symbol] += 1;
    }

    let mut tail_count = 0usize;
    for &value in &symbols[..n] {
        let symbol = value as usize;
        let mut count = position_count[symbol] as usize;
        while count > 0 {
            count -= 1;
            let position = right_positions[symbol][count];
            let mut low = 0usize;
            let mut high = tail_count;
            while low < high {
                let middle = low + (high - low) / 2;
                if tails[middle] >= position {
                    high = middle;
                } else {
                    low = middle + 1;
                }
            }
            if low == tail_count {
                tails[tail_count] = position;
                tail_count += 1;
            } else {
                tails[low] = position;
            }
        }
    }
    tail_count as i64
}
