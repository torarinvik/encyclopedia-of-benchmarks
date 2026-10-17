const MAX_N: usize = 8;
const MAX_INPUT_LENGTH: usize = 129;

#[no_mangle]
pub unsafe extern "C" fn stable_matching(
    input: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if input.is_null() || length < 1 || length > MAX_INPUT_LENGTH {
        return -1;
    }
    let n_value = *input;
    if n_value < 0 || n_value > MAX_N as i64 {
        return -1;
    }
    let n = n_value as usize;
    let side_size = n * n;
    if length != 1 + 2 * side_size {
        return -1;
    }

    let mut men_preferences = [0i64; 64];
    let mut women_rank = [0i64; 64];
    for row in 0..2 * n {
        let mut seen = [false; MAX_N];
        let row_start = if row < n {
            1 + row * n
        } else {
            1 + side_size + (row - n) * n
        };
        for rank in 0..n {
            let participant = *input.add(row_start + rank);
            if participant < 0 || participant >= n_value || seen[participant as usize] {
                return -1;
            }
            seen[participant as usize] = true;
            if row < n {
                men_preferences[row * n + rank] = participant;
            } else {
                women_rank[(row - n) * n + participant as usize] = rank as i64;
            }
        }
    }

    let output_bytes = 16 * n;
    if output.is_null() || capacity < output_bytes {
        return -2;
    }

    let mut woman_partner = [-1i64; MAX_N];
    let mut man_partner = [-1i64; MAX_N];
    let mut next_proposal = [0usize; MAX_N];
    let mut free_queue = [0usize; MAX_N];
    for index in 0..n {
        free_queue[index] = index;
    }
    let (mut head, mut tail, mut queue_count) = (0usize, 0usize, n);
    while queue_count > 0 {
        let man = free_queue[head];
        head = (head + 1) % n;
        queue_count -= 1;
        let rank = next_proposal[man];
        next_proposal[man] += 1;
        let woman = men_preferences[man * n + rank] as usize;
        let incumbent = woman_partner[woman];
        if incumbent < 0 {
            woman_partner[woman] = man as i64;
            man_partner[man] = woman as i64;
        } else if women_rank[woman * n + man] < women_rank[woman * n + incumbent as usize] {
            woman_partner[woman] = man as i64;
            man_partner[man] = woman as i64;
            man_partner[incumbent as usize] = -1;
            free_queue[tail] = incumbent as usize;
            tail = (tail + 1) % n;
            queue_count += 1;
        } else {
            free_queue[tail] = man;
            tail = (tail + 1) % n;
            queue_count += 1;
        }
    }

    for man in 0..n {
        let pair = [man as i64, man_partner[man]];
        for (item, value) in pair.iter().enumerate() {
            let bytes = value.to_le_bytes();
            std::ptr::copy_nonoverlapping(bytes.as_ptr(), output.add((man * 2 + item) * 8), 8);
        }
    }
    output_bytes as i64
}
