const MAX_N: usize = 5;
const MAX_F: usize = 5;
const MAX_Q: usize = 8;
const MAX_P: usize = 10;
const MAX_PARSEABLE: usize = 128;

unsafe fn put(out: *mut u8, at: usize, value: i64) {
    let bits = value as u64;
    for i in 0..8 { *out.add(at + i) = (bits >> (8 * i)) as u8; }
}
fn state_cost(n: usize, f: usize, d: &[[i64; MAX_P]; MAX_P], demand: &[i64; MAX_N],
              assignment: &[i64; MAX_N], fee: &[i64; MAX_F], mask: u32) -> i64 {
    let mut total = 0;
    for s in 0..f { if mask & (1 << s) != 0 { total += fee[s]; } }
    for j in 0..n { total += demand[j] * d[j][n + assignment[j] as usize]; }
    total
}

#[no_mangle]
pub unsafe extern "C" fn facility_location_randomized_add_delete_many(
    input: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if input.is_null() || length < 12 || length > MAX_PARSEABLE { return -1; }
    let n0 = *input; let f0 = *input.add(1); let q0 = *input.add(2); let raw = *input.add(3);
    if n0 < 1 || n0 > 5 || f0 < 1 || f0 > 5 || q0 < 1 || q0 > 8
        || raw <= 0 || raw as u64 >= (1u64 << f0) { return -1; }
    let n = n0 as usize; let f = f0 as usize; let q = q0 as usize; let p = n + f;
    if length != 4 + 2 * n + p * p + f + q { return -1; }
    let mut mask = raw as u32;
    let mut assignment = [0i64; MAX_N]; let mut demand = [0i64; MAX_N];
    let mut d = [[0i64; MAX_P]; MAX_P]; let mut fee = [0i64; MAX_F]; let mut tape = [0i64; MAX_Q];
    let mut at = 4;
    for j in 0..n { assignment[j] = *input.add(at); at += 1;
        if assignment[j] < 0 || assignment[j] >= f0 || mask & (1 << assignment[j]) == 0 { return -1; } }
    for j in 0..n { demand[j] = *input.add(at); at += 1; if demand[j] < 1 || demand[j] > 10 { return -1; } }
    for i in 0..p { for j in 0..p { let v = *input.add(at); at += 1; if v < 0 || v > 1000 { return -1; } d[i][j] = v; } }
    for i in 0..p { if d[i][i] != 0 { return -1; } for j in 0..p {
        if i != j && d[i][j] == 0 { return -1; }
        if d[i][j] != d[j][i] { return -1; }
        for k in 0..p { if d[i][j] > d[i][k] + d[k][j] { return -1; } }
    } }
    for s in 0..f { fee[s] = *input.add(at); at += 1; if fee[s] < 0 || fee[s] > 1000 { return -1; } }
    for t in 0..q { tape[t] = *input.add(at); at += 1; if tape[t] < 0 || tape[t] >= f0 { return -1; } }
    let mut costs = [0i64; MAX_Q]; let mut accepted = [0i64; MAX_Q];
    let mut current = state_cost(n, f, &d, &demand, &assignment, &fee, mask); let mut count = 0i64;
    for step in 0..q {
        let candidate = tape[step] as usize; let bit = 1u32 << candidate; let mut did = 0;
        if mask & bit == 0 {
            let mut closer = [false; MAX_N]; let mut gain = -fee[candidate];
            for j in 0..n { let old = assignment[j] as usize;
                if d[j][n + candidate] < d[j][n + old] { closer[j] = true; gain += demand[j] * (d[j][n + old] - d[j][n + candidate]); }
            }
            let mut drop = 0u32;
            for s in 0..f { if mask & (1 << s) != 0 {
                let mut cg = fee[s];
                for j in 0..n { if assignment[j] as usize == s && !closer[j] { cg += demand[j] * (d[j][n + s] - d[j][n + candidate]); } }
                if cg > 0 { drop |= 1 << s; gain += cg; }
            } }
            if gain > 0 {
                mask = (mask | bit) & !drop;
                for j in 0..n { if closer[j] || drop & (1 << assignment[j]) != 0 { assignment[j] = candidate as i64; } }
                current = state_cost(n, f, &d, &demand, &assignment, &fee, mask); did = 1; count += 1;
            }
        }
        costs[step] = current; accepted[step] = did;
    }
    let bytes = 8 * (2 * q + 3 + n);
    if output.is_null() || capacity < bytes { return -2; }
    at = 0;
    for t in 0..q { put(output, at, costs[t]); at += 8; }
    for t in 0..q { put(output, at, accepted[t]); at += 8; }
    put(output, at, current); at += 8; put(output, at, mask as i64); at += 8;
    for j in 0..n { put(output, at, assignment[j]); at += 8; }
    put(output, at, count); at += 8;
    at as i64
}
