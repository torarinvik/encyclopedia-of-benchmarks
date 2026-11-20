const MAX_STATES: usize = 8;
const MAX_ALPHABET: usize = 3;

#[no_mangle]
pub unsafe extern "C" fn moore_dfa_minimization(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 4 || length > 29 { return -1; }
    let values = unsafe { std::slice::from_raw_parts(input, length) };
    let n64 = values[0];
    let alphabet64 = values[1];
    let start64 = values[2];
    let accepting = values[3];
    if !(1..=MAX_STATES as i64).contains(&n64) || !(1..=MAX_ALPHABET as i64).contains(&alphabet64)
        || start64 < 0 || start64 >= n64 || accepting < 0 || accepting >= (1i64 << n64) { return -1; }
    let n = n64 as usize;
    let alphabet = alphabet64 as usize;
    if length != 4 + n * alphabet { return -1; }
    let mut transition = [[0usize; MAX_ALPHABET]; MAX_STATES];
    for s in 0..n { for a in 0..alphabet {
        let target = values[4 + s * alphabet + a];
        if target < 0 || target >= n64 { return -1; }
        transition[s][a] = target as usize;
    } }
    let mut labels = [0usize; MAX_STATES];
    let mut refined = [0usize; MAX_STATES];
    let mut acceptance_id = [usize::MAX; 2];
    let mut classes = 0usize;
    for s in 0..n {
        let bit = ((accepting >> s) & 1) as usize;
        if acceptance_id[bit] == usize::MAX { acceptance_id[bit] = classes; classes += 1; }
        labels[s] = acceptance_id[bit];
    }
    let mut rounds = 0usize;
    loop {
        let mut signatures = [0usize; MAX_STATES];
        let mut signature_count = 0usize;
        for s in 0..n {
            let mut signature = labels[s];
            for a in 0..alphabet { signature = signature * 8 + labels[transition[s][a]]; }
            let mut id = 0;
            while id < signature_count && signatures[id] != signature { id += 1; }
            if id == signature_count { signatures[signature_count] = signature; signature_count += 1; }
            refined[s] = id;
        }
        let changed = (0..n).any(|s| refined[s] != labels[s]);
        if !changed { classes = signature_count; break; }
        labels[..n].copy_from_slice(&refined[..n]);
        classes = signature_count;
        rounds += 1;
    }
    let mut packed = ((classes as i64) << 28) | ((rounds as i64) << 24);
    for s in 0..n { packed |= (labels[s] as i64) << (3 * s); }
    packed
}
