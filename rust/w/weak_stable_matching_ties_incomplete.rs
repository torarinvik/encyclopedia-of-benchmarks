const MAX_N: usize = 6;
const MAX_INPUT: usize = 73;
const MAX_OUTPUT_BYTES: usize = 104;

#[no_mangle]
pub unsafe extern "C" fn weak_stable_matching_ties_incomplete(
    input: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if input.is_null() || length < 1 || length > MAX_INPUT { return -1; }
    let n_raw = *input;
    if n_raw < 1 || n_raw > MAX_N as i64 { return -1; }
    let n = n_raw as usize;
    let side_size = n * n;
    if length != 1 + 2 * side_size { return -1; }
    let mut men_rank = [[0i64; MAX_N]; MAX_N];
    let mut women_rank = [[0i64; MAX_N]; MAX_N];
    let mut choices = [[0usize; MAX_N]; MAX_N];
    let mut choice_count = [0usize; MAX_N];
    for man in 0..n { for woman in 0..n {
        let rank = *input.add(1 + man * n + woman);
        if rank < 0 || rank > n_raw { return -1; }
        men_rank[man][woman] = rank;
    }}
    for woman in 0..n { for man in 0..n {
        let rank = *input.add(1 + side_size + woman * n + man);
        if rank < 0 || rank > n_raw || (rank > 0) != (men_rank[man][woman] > 0) { return -1; }
        women_rank[woman][man] = rank;
    }}
    for man in 0..n { for woman in 0..n {
        if men_rank[man][woman] == 0 { continue; }
        let mut at = choice_count[man];
        while at > 0 {
            let prior = choices[man][at - 1];
            if men_rank[man][prior] < men_rank[man][woman] ||
                    (men_rank[man][prior] == men_rank[man][woman] && prior < woman) { break; }
            choices[man][at] = prior;
            at -= 1;
        }
        choices[man][at] = woman;
        choice_count[man] += 1;
    }}
    let mut man_partner = [-1i32; MAX_N];
    let mut woman_partner = [-1i32; MAX_N];
    let mut next_choice = [0usize; MAX_N];
    loop {
        let mut man = None;
        for candidate in 0..n {
            if man_partner[candidate] < 0 && next_choice[candidate] < choice_count[candidate] {
                man = Some(candidate); break;
            }
        }
        let m = match man { Some(value) => value, None => break };
        let woman = choices[m][next_choice[m]];
        next_choice[m] += 1;
        let incumbent = woman_partner[woman];
        if incumbent < 0 || women_rank[woman][m] < women_rank[woman][incumbent as usize] ||
                (women_rank[woman][m] == women_rank[woman][incumbent as usize] && m < incumbent as usize) {
            woman_partner[woman] = m as i32;
            man_partner[m] = woman as i32;
            if incumbent >= 0 { man_partner[incumbent as usize] = -1; }
        }
    }
    let mut words = [0i64; 1 + 2 * MAX_N];
    let mut pairs = 0usize;
    for man in 0..n { if man_partner[man] >= 0 {
        words[1 + 2 * pairs] = man as i64;
        words[2 + 2 * pairs] = man_partner[man] as i64;
        pairs += 1;
    }}
    words[0] = pairs as i64;
    let output_bytes = 8 * (1 + 2 * pairs);
    if output.is_null() || capacity < output_bytes { return -2; }
    let mut staged = [0u8; MAX_OUTPUT_BYTES];
    for word in 0..1 + 2 * pairs {
        let bytes = words[word].to_le_bytes();
        std::ptr::copy_nonoverlapping(bytes.as_ptr(), staged.as_mut_ptr().add(8 * word), 8);
    }
    std::ptr::copy_nonoverlapping(staged.as_ptr(), output, output_bytes);
    output_bytes as i64
}
