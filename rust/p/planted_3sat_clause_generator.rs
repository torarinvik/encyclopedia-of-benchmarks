//! Unverified deterministic planted 3-SAT generator draft.

fn generate(input: &[i64]) -> Option<Vec<u8>> {
    if input.len() < 5 || input.len() > 83 || !(3..=16).contains(&input[0]) || !(0..=32).contains(&input[1]) {
        return None;
    }
    let n = input[0] as usize;
    let m = input[1] as usize;
    if input.len() != 2+n+2*m || input[2..2+n].iter().any(|&v| v != 0 && v != 1) { return None; }
    let choices = n*(n-1)*(n-2)/6;
    let mut output = Vec::with_capacity(24*m);
    for clause in 0..m {
        let raw = input[2+n+2*clause];
        let mask = input[3+n+2*clause];
        if raw < 0 || raw as usize >= choices || !(1..=7).contains(&mask) { return None; }
        let mut rank = raw as usize;
        let mut next = 0;
        for position in 0..3 {
            for variable in next..n-(2-position) {
                let remaining = n-variable-1;
                let ways = if position == 0 { remaining*(remaining-1)/2 } else if position == 1 { remaining } else { 1 };
                if rank >= ways { rank -= ways; continue; }
                let value = (variable+1) as i64;
                let literal = if input[2+variable] == ((mask >> position) & 1) { value } else { -value };
                output.extend_from_slice(&literal.to_le_bytes());
                next = variable+1;
                break;
            }
        }
    }
    Some(output)
}

#[no_mangle]
pub unsafe extern "C" fn planted_3sat_clause_generator(input: *const i64, length: usize,
                                                        output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 5 || length > 83 { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let bytes = match generate(values) { Some(bytes) => bytes, None => return -1 };
    if !bytes.is_empty() && (output.is_null() || capacity < bytes.len()) { return -2; }
    if !bytes.is_empty() { std::ptr::copy_nonoverlapping(bytes.as_ptr(), output, bytes.len()); }
    bytes.len() as i64
}
