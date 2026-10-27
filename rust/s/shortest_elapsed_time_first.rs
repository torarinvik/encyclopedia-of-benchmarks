const MAX_JOBS: usize = 8;
const MAX_INPUT: usize = 18;
const MAX_OUTPUT: usize = 112;

#[no_mangle]
pub unsafe extern "C" fn shortest_elapsed_time_first(
    input: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if input.is_null() || length < 1 || length > MAX_INPUT { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let n64 = values[0];
    if n64 < 0 || n64 > MAX_JOBS as i64 || length != 1 + 2 * n64 as usize { return -1; }
    let n = n64 as usize;
    let mut release = [0i64; MAX_JOBS];
    let mut remaining = [0i64; MAX_JOBS];
    let mut attained = [0i64; MAX_JOBS];
    for job in 0..n {
        release[job] = values[1 + 2 * job];
        remaining[job] = values[2 + 2 * job];
        if !(0..=16).contains(&release[job]) || !(1..=12).contains(&remaining[job]) { return -1; }
    }
    if output.is_null() { return -2; }
    let mut trace = [0u8; MAX_OUTPUT];
    let (mut time, mut completed) = (0usize, 0usize);
    while completed < n && time < MAX_OUTPUT {
        let mut chosen = n;
        for job in 0..n {
            if release[job] <= time as i64 && remaining[job] > 0 &&
                (chosen == n || attained[job] < attained[chosen]) { chosen = job; }
        }
        if chosen < n {
            trace[time] = (chosen + 1) as u8;
            attained[chosen] += 1;
            remaining[chosen] -= 1;
            if remaining[chosen] == 0 { completed += 1; }
        }
        time += 1;
    }
    if completed != n { return -1; }
    if capacity < time { return -2; }
    std::ptr::copy_nonoverlapping(trace.as_ptr(), output, time);
    time as i64
}
