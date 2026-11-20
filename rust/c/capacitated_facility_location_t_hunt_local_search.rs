const MAX_N: usize = 4;
const MAX_F: usize = 3;
const MAX_Q: usize = 4;
const MAX_COPIES: usize = 644;
const MAX_CANDIDATES: usize = 648;
const MAX_P: usize = 7;
const MAX_PARSEABLE: usize = 63;
const NEG: i64 = i64::MIN / 4;

unsafe fn put_word(output: *mut u8, at: usize, value: i64) {
    for (offset, byte) in value.to_le_bytes().iter().enumerate() {
        *output.add(at + offset) = *byte;
    }
}

fn assign_state(n: usize, f: usize, d: &[[i64; MAX_P]; MAX_P], fee: &[i64; MAX_F],
    cap: &[i64; MAX_F], types: &[i64; MAX_CANDIDATES], copies: usize,
    assignment: &mut [i64; MAX_N]) -> i64 {
    let mut multiplicity = [0usize; MAX_F];
    for i in 0..copies { multiplicity[types[i] as usize] += 1; }
    let combinations = f.pow(n as u32);
    let mut best = i64::MAX;
    let mut best_types = [0i64; MAX_N];
    for code in 0..combinations {
        let mut rem = code;
        let mut candidate = [0i64; MAX_N];
        let mut loads = [0usize; MAX_F];
        let mut service = 0i64;
        for j in (0..n).rev() {
            let kind = rem % f;
            rem /= f;
            candidate[j] = kind as i64;
            loads[kind] += 1;
            service += d[j][n + kind];
        }
        let feasible = (0..f).all(|kind| loads[kind] <= multiplicity[kind] * cap[kind] as usize);
        if feasible && service < best {
            best = service;
            best_types = candidate;
        }
    }
    let mut copy_load = [0usize; MAX_CANDIDATES];
    for j in 0..n {
        assignment[j] = -1;
        for i in 0..copies {
            let kind = types[i] as usize;
            if kind == best_types[j] as usize && copy_load[i] < cap[kind] as usize {
                assignment[j] = i as i64;
                copy_load[i] += 1;
                break;
            }
        }
    }
    best + (0..copies).map(|i| fee[types[i] as usize]).sum::<i64>()
}

fn insert_type(types: &mut [i64; MAX_CANDIDATES], count: usize, kind: i64) -> usize {
    let mut at = count;
    while at > 0 && types[at - 1] > kind {
        types[at] = types[at - 1];
        at -= 1;
    }
    types[at] = kind;
    count + 1
}

fn hunt(n: usize, d: &[[i64; MAX_P]; MAX_P], fee: &[i64; MAX_F],
    cap: &[i64; MAX_F], types: &[i64; MAX_CANDIDATES], copies: usize,
    assignment: &[i64; MAX_N], target: usize, l: usize,
    loads: &mut [usize; MAX_COPIES], profits: &mut [i64; MAX_COPIES],
    take: &mut [[bool; MAX_N + 1]; MAX_COPIES], selected: &mut [bool; MAX_COPIES]) -> i64 {
    for i in 0..copies { loads[i] = 0; profits[i] = fee[types[i] as usize]; }
    for j in 0..n {
        let copy = assignment[j] as usize;
        loads[copy] += 1;
        let old = types[copy] as usize;
        profits[copy] += d[j][n + old] - d[j][n + target];
    }
    let limit = std::cmp::min(n, l * cap[target] as usize);
    let mut dp = [NEG; MAX_N + 1];
    dp[0] = 0;
    for i in 0..copies {
        let mut next = dp;
        for w in 0..=limit { take[i][w] = false; }
        for w in 0..=limit {
            if dp[w] == NEG || w + loads[i] > limit { continue; }
            let nw = w + loads[i];
            let value = dp[w] + profits[i];
            if value > next[nw] { next[nw] = value; take[i][nw] = true; }
        }
        dp = next;
    }
    let mut best = NEG;
    let mut best_weight = 0;
    for w in 0..=limit { if dp[w] > best { best = dp[w]; best_weight = w; } }
    selected[..copies].fill(false);
    for i in (0..copies).rev() {
        if take[i][best_weight] { selected[i] = true; best_weight -= loads[i]; }
    }
    best
}

#[no_mangle]
pub unsafe extern "C" fn capacitated_facility_location_t_hunt_local_search(
    input: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if input.is_null() || length < 10 || length > MAX_PARSEABLE { return -1; }
    let n0 = *input;
    let f0 = *input.add(1);
    let q0 = *input.add(2);
    if n0 < 1 || n0 > MAX_N as i64 || f0 < 1 || f0 > MAX_F as i64
        || q0 < 1 || q0 > MAX_Q as i64 { return -1; }
    let n = n0 as usize;
    let f = f0 as usize;
    let q = q0 as usize;
    let p = n + f;
    if length != 3 + p * p + 2 * f + q { return -1; }
    let mut d = [[0i64; MAX_P]; MAX_P];
    let mut fee = [0i64; MAX_F];
    let mut cap = [0i64; MAX_F];
    let mut types = [0i64; MAX_CANDIDATES];
    let mut at = 3;
    for i in 0..p { for j in 0..p {
        let value = *input.add(at); at += 1;
        if !(0..=20).contains(&value) { return -1; }
        d[i][j] = value;
    }}
    for i in 0..p {
        if d[i][i] != 0 { return -1; }
        for j in 0..p {
            if i != j && d[i][j] == 0 { return -1; }
            if d[i][j] != d[j][i] { return -1; }
            for k in 0..p { if d[i][j] > d[i][k] + d[k][j] { return -1; } }
        }
    }
    for i in 0..f { fee[i] = *input.add(at); at += 1; if !(0..=20).contains(&fee[i]) { return -1; } }
    for i in 0..f { cap[i] = *input.add(at); at += 1; if cap[i] < 1 || cap[i] > n0 { return -1; } }
    let mut copies = q;
    let mut total_capacity = 0usize;
    for i in 0..q {
        let value = *input.add(at); at += 1;
        if value < 0 || value >= f0 { return -1; }
        types[i] = value;
        total_capacity += cap[value as usize] as usize;
    }
    if total_capacity < n { return -1; }
    types[..copies].sort();
    let mut assignment = [0i64; MAX_N];
    let mut current = assign_state(n, f, &d, &fee, &cap, &types, copies, &mut assignment);
    let mut steps = 0usize;
    while steps < 160 {
        let mut moved = false;
        for target in 0..f {
            let mut candidate_types = types;
            let mut candidate_count = insert_type(&mut candidate_types, copies, target as i64);
            let mut candidate_assignment = [0i64; MAX_N];
            let mut candidate_cost = assign_state(n, f, &d, &fee, &cap, &candidate_types,
                candidate_count, &mut candidate_assignment);
            if candidate_cost < current {
                types = candidate_types; copies = candidate_count; current = candidate_cost;
                assignment = candidate_assignment; steps += 1; moved = true; break;
            }
            let mut loads = [0usize; MAX_COPIES];
            let mut profits = [0i64; MAX_COPIES];
            let mut take = [[false; MAX_N + 1]; MAX_COPIES];
            let mut selected = [false; MAX_COPIES];
            for l in 1..=n {
                let profit = hunt(n, &d, &fee, &cap, &types, copies, &assignment,
                    target, l, &mut loads, &mut profits, &mut take, &mut selected);
                if profit <= l as i64 * fee[target] { continue; }
                candidate_types = [0; MAX_CANDIDATES];
                candidate_count = 0;
                for i in 0..copies { if !selected[i] { candidate_types[candidate_count] = types[i]; candidate_count += 1; } }
                for _ in 0..l { candidate_count = insert_type(&mut candidate_types, candidate_count, target as i64); }
                candidate_cost = assign_state(n, f, &d, &fee, &cap, &candidate_types,
                    candidate_count, &mut candidate_assignment);
                if candidate_cost < current {
                    types = candidate_types; copies = candidate_count; current = candidate_cost;
                    assignment = candidate_assignment; steps += 1; moved = true; break;
                }
            }
            if moved { break; }
        }
        if !moved { break; }
    }
    let words = 3 + copies + n;
    let bytes = words * 8;
    if output.is_null() || capacity < bytes { return -2; }
    let mut pos = 0;
    put_word(output, pos, current); pos += 8;
    put_word(output, pos, steps as i64); pos += 8;
    put_word(output, pos, copies as i64); pos += 8;
    for i in 0..copies { put_word(output, pos, types[i]); pos += 8; }
    for j in 0..n { put_word(output, pos, assignment[j]); pos += 8; }
    bytes as i64
}
