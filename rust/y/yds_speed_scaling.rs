const MAX_JOBS: usize = 4;
const MAX_TIME: usize = 8;
const MAX_INPUT: usize = 13;
const MAX_OUTPUT: usize = 152;

fn gcd(mut a: i64, mut b: i64) -> i64 {
    while b != 0 { let r = a % b; a = b; b = r; }
    a
}

unsafe fn put64(output: *mut u8, at: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 { *output.add(at + byte) = (bits >> (8 * byte)) as u8; }
}

#[no_mangle]
pub unsafe extern "C" fn yds_speed_scaling(input: *const i64, length: usize,
    output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 4 || length > MAX_INPUT { return -1; }
    let n64 = *input;
    if n64 < 1 || n64 > MAX_JOBS as i64 { return -1; }
    let n = n64 as usize;
    if length != 1 + 3 * n { return -1; }
    let mut release = [0usize; MAX_JOBS];
    let mut deadline = [0usize; MAX_JOBS];
    let mut work = [0i64; MAX_JOBS];
    let mut active = [false; MAX_JOBS];
    for j in 0..n {
        let r = *input.add(1 + 3*j);
        let d = *input.add(2 + 3*j);
        let w = *input.add(3 + 3*j);
        if r < 0 || r >= d || d > MAX_TIME as i64 || w < 1 || w > 8 { return -1; }
        release[j] = r as usize; deadline[j] = d as usize; work[j] = w; active[j] = true;
    }
    let mut staged = [0i64; MAX_OUTPUT / 8];
    let mut output_values = 3usize;
    let mut stages = 0i64;
    let mut energy_num = 0i64;
    let mut energy_den = 1i64;
    let mut remaining = n;
    while remaining > 0 {
        let mut release_seen = [false; MAX_TIME + 1];
        let mut deadline_seen = [false; MAX_TIME + 1];
        for j in 0..n { if active[j] { release_seen[release[j]] = true; deadline_seen[deadline[j]] = true; } }
        let mut have_best = false;
        let mut best_a = 0usize;
        let mut best_b = 1usize;
        let mut best_work = 0i64;
        let mut best_duration = 1i64;
        for a in 0..=MAX_TIME {
            if !release_seen[a] { continue; }
            for b in a+1..=MAX_TIME {
                if !deadline_seen[b] { continue; }
                let mut total = 0i64;
                for j in 0..n { if active[j] && release[j] >= a && deadline[j] <= b { total += work[j]; } }
                if total == 0 { continue; }
                let duration = (b - a) as i64;
                if !have_best || total * best_duration > best_work * duration ||
                    (total * best_duration == best_work * duration && (a < best_a || (a == best_a && b < best_b))) {
                    have_best = true; best_a = a; best_b = b; best_work = total; best_duration = duration;
                }
            }
        }
        if !have_best { return -1; }
        let mut job_mask = 0i64;
        for j in 0..n {
            if active[j] && release[j] >= best_a && deadline[j] <= best_b {
                job_mask |= 1i64 << j;
            }
        }
        staged[output_values] = best_a as i64; output_values += 1;
        staged[output_values] = best_b as i64; output_values += 1;
        staged[output_values] = best_work; output_values += 1;
        staged[output_values] = job_mask; output_values += 1;

        let term_num = best_work * best_work * best_work;
        let term_den = best_duration * best_duration;
        let common = gcd(energy_den, term_den);
        energy_num = energy_num * (term_den / common) + term_num * (energy_den / common);
        energy_den *= term_den / common;
        let energy_gcd = gcd(energy_num, energy_den);
        energy_num /= energy_gcd; energy_den /= energy_gcd;

        for j in 0..n {
            if !active[j] { continue; }
            if release[j] >= best_a && deadline[j] <= best_b {
                active[j] = false; remaining -= 1;
            } else {
                if release[j] > best_a && release[j] < best_b { release[j] = best_a; }
                else if release[j] >= best_b { release[j] -= best_duration as usize; }
                if deadline[j] > best_a && deadline[j] < best_b { deadline[j] = best_a; }
                else if deadline[j] >= best_b { deadline[j] -= best_duration as usize; }
            }
        }
        stages += 1;
    }
    staged[0] = stages; staged[1] = energy_num; staged[2] = energy_den;
    let output_bytes = 8 * output_values;
    if output.is_null() || capacity < output_bytes { return -2; }
    let mut bytes = [0u8; MAX_OUTPUT];
    for i in 0..output_values { put64(bytes.as_mut_ptr(), 8*i, staged[i]); }
    for i in 0..output_bytes { *output.add(i) = bytes[i]; }
    output_bytes as i64
}
