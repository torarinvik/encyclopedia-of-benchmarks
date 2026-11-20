const MAX_STATES: usize = 8;
const MAX_STEPS: usize = 64;
const MAX_INPUT: usize = 267;
const MAX_OUTPUT: usize = 65;

#[no_mangle]
pub unsafe extern "C" fn metropolis_hastings_asymmetric_proposal(
    input: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if input.is_null() || length < 3 || length > MAX_INPUT {
        return -1;
    }
    let values = unsafe { std::slice::from_raw_parts(input, length) };
    let n64 = values[0];
    let steps64 = values[1];
    let initial64 = values[2];
    if n64 < 2 || n64 > MAX_STATES as i64 || steps64 < 0 || steps64 > MAX_STEPS as i64
        || initial64 < 0 || initial64 >= n64
    {
        return -1;
    }
    let n = n64 as usize;
    let steps = steps64 as usize;
    let weights_start = 3;
    let matrix_start = weights_start + n;
    let proposals_start = matrix_start + n * n;
    let draws_start = proposals_start + steps;
    if length != draws_start + 2 * steps {
        return -1;
    }
    if values[weights_start..matrix_start].iter().any(|&w| !(1..=1024).contains(&w)) {
        return -1;
    }
    for row in 0..n {
        let start = matrix_start + row * n;
        let q = &values[start..start + n];
        if q.iter().any(|&v| !(0..=1024).contains(&v)) || q.iter().sum::<i64>() != 1024 {
            return -1;
        }
    }

    let mut staged = [0u8; MAX_OUTPUT];
    let mut current = initial64 as usize;
    staged[0] = current as u8;
    for step in 0..steps {
        let proposal64 = values[proposals_start + step];
        let draw_num = values[draws_start + 2 * step];
        let draw_den = values[draws_start + 2 * step + 1];
        if proposal64 < 0 || proposal64 >= n64 || draw_den < 1 || draw_den > 1024
            || draw_num < 0 || draw_num >= draw_den
        {
            return -1;
        }
        let proposal = proposal64 as usize;
        let forward = values[matrix_start + current * n + proposal];
        if forward == 0 {
            return -1;
        }
        let reverse = values[matrix_start + proposal * n + current];
        let numerator = values[weights_start + proposal] * reverse;
        let denominator = values[weights_start + current] * forward;
        if numerator >= denominator || draw_num * denominator < draw_den * numerator {
            current = proposal;
        }
        staged[step + 1] = current as u8;
    }
    let needed = steps + 1;
    if output.is_null() || capacity < needed {
        return -2;
    }
    unsafe { std::ptr::copy_nonoverlapping(staged.as_ptr(), output, needed) };
    needed as i64
}
