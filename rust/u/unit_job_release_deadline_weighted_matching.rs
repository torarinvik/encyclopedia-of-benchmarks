fn assign(job: usize, release: &[usize; 32], deadline: &[usize; 32],
          slots: &mut [Option<usize>; 32], seen: &mut [bool; 32]) -> bool {
    for slot in release[job]..=deadline[job] {
        if seen[slot] { continue; }
        seen[slot] = true;
        if slots[slot].is_none() || assign(slots[slot].unwrap(), release, deadline, slots, seen) {
            slots[slot] = Some(job);
            return true;
        }
    }
    false
}

#[no_mangle]
pub unsafe extern "C" fn unit_job_release_deadline_weighted_matching(input: *const i64, length: usize) -> i64 {
    if input.is_null() || !(1..=98).contains(&length) { return -1; }
    let input = std::slice::from_raw_parts(input, length);
    if !(0..=32).contains(&input[0]) { return -1; }
    let n = input[0] as usize;
    if length != 1 + 3*n { return -1; }
    let mut release = [0; 32]; let mut deadline = [0; 32];
    let mut weight = [0i64; 32]; let mut order: Vec<usize> = Vec::with_capacity(n);
    for i in 0..n {
        let (r, d, w) = (input[1+3*i], input[2+3*i], input[3+3*i]);
        if r < 0 || d < r || d >= 32 || !(0..=1_000_000).contains(&w) { return -1; }
        release[i] = r as usize; deadline[i] = d as usize; weight[i] = w;
        order.push(i);
    }
    order.sort_by_key(|&i| std::cmp::Reverse(weight[i]));
    let mut slots = [None; 32]; let mut total = 0;
    for job in order {
        if assign(job, &release, &deadline, &mut slots, &mut [false; 32]) { total += weight[job]; }
    }
    total
}
