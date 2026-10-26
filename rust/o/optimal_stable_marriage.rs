const MAX_N: usize = 8;
const MAX_INPUT_LENGTH: usize = 129;

fn store_i64_le(output: *mut u8, offset: usize, value: i64) {
    let bytes = value.to_le_bytes();
    unsafe { std::ptr::copy_nonoverlapping(bytes.as_ptr(), output.add(offset), 8); }
}

#[no_mangle]
pub unsafe extern "C" fn optimal_stable_marriage(
    input: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if input.is_null() || length < 1 || length > MAX_INPUT_LENGTH { return -1; }
    let n_value = *input;
    if n_value < 0 || n_value > MAX_N as i64 { return -1; }
    let n = n_value as usize;
    let side_size = n * n;
    if length != 1 + 2 * side_size { return -1; }

    let mut men_preferences = [0usize; 64];
    let mut women_rank = [0usize; 64];
    for row in 0..2 * n {
        let mut seen = [false; MAX_N];
        let start = if row < n { 1 + row * n } else { 1 + side_size + (row - n) * n };
        for rank in 0..n {
            let value = *input.add(start + rank);
            if value < 0 || value >= n_value || seen[value as usize] { return -1; }
            let participant = value as usize;
            seen[participant] = true;
            if row < n { men_preferences[row * n + rank] = participant; }
            else { women_rank[(row - n) * n + participant] = rank; }
        }
    }
    let output_bytes = 16 * n;
    if output.is_null() || capacity < output_bytes { return -2; }

    let mut final_partner = [-1i64; MAX_N];
    for threshold in 0..n {
        let mut woman_partner = [-1i64; MAX_N];
        let mut man_partner = [-1i64; MAX_N];
        let mut next_rank = [0usize; MAX_N];
        let mut queue = [0usize; MAX_N];
        for i in 0..n { queue[i] = i; }
        let (mut head, mut tail, mut queued) = (0usize, 0usize, n);
        while queued > 0 {
            let man = queue[head];
            head = (head + 1) % n;
            queued -= 1;
            while next_rank[man] < n {
                let rank = next_rank[man];
                next_rank[man] += 1;
                let woman = men_preferences[man * n + rank];
                if rank > threshold || women_rank[woman * n + man] > threshold { continue; }
                let incumbent = woman_partner[woman];
                if incumbent < 0 || women_rank[woman * n + man] < women_rank[woman * n + incumbent as usize] {
                    woman_partner[woman] = man as i64;
                    man_partner[man] = woman as i64;
                    if incumbent >= 0 {
                        man_partner[incumbent as usize] = -1;
                        queue[tail] = incumbent as usize;
                        tail = (tail + 1) % n;
                        queued += 1;
                    }
                    break;
                }
                queue[tail] = man;
                tail = (tail + 1) % n;
                queued += 1;
                break;
            }
        }
        if (0..n).all(|man| man_partner[man] >= 0) {
            for man in 0..n { final_partner[man] = man_partner[man]; }
            break;
        }
    }
    for man in 0..n {
        store_i64_le(output, (man * 2) * 8, man as i64);
        store_i64_le(output, (man * 2 + 1) * 8, final_partner[man]);
    }
    output_bytes as i64
}
