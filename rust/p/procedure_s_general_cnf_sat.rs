const MAX_VARS: usize = 5;
const MAX_CLAUSES: usize = 6;
const MAX_LITS: usize = MAX_VARS * MAX_CLAUSES;

#[derive(Clone, Copy)]
struct Formula { count: usize, length: [usize; MAX_CLAUSES], literal: [i8; MAX_LITS] }
#[derive(Default)]
struct Stats { calls: i64, tests: i64, branches: i64, max_depth: i64 }

fn put_i64(out: &mut [u8], word: usize, value: i64) { out[word * 8..word * 8 + 8].copy_from_slice(&value.to_le_bytes()); }
fn shorten(f: &Formula, k: usize) -> Formula {
    let mut d = Formula { count: f.count, length: [0; MAX_CLAUSES], literal: [0; MAX_LITS] };
    for c in 0..f.count { d.length[c] = f.length[c].min(k); for j in 0..d.length[c] { d.literal[c * MAX_VARS + j] = f.literal[c * MAX_VARS + j]; } }
    d
}
fn exact_sat(f: &Formula, n: usize, fixed_mask: u32, fixed_values: u32) -> Option<u32> {
    for code in 0..(1u32 << n) {
        let mut candidate = 0u32;
        for v in 0..n { if (code >> (n - v - 1)) & 1 != 0 { candidate |= 1 << v; } }
        if (candidate ^ fixed_values) & fixed_mask != 0 { continue; }
        let sat = (0..f.count).all(|c| (0..f.length[c]).any(|j| {
            let lit = f.literal[c * MAX_VARS + j] as i32;
            let truth = (candidate >> (if lit > 0 { lit - 1 } else { -lit - 1 })) & 1 != 0;
            (lit > 0 && truth) || (lit < 0 && !truth)
        }));
        if sat { return Some(candidate); }
    }
    None
}
fn solve(f: Formula, n: usize, k: usize, fixed_mask: u32, fixed_values: u32,
         depth: i64, stats: &mut Stats) -> Option<u32> {
    stats.calls += 1; stats.max_depth = stats.max_depth.max(depth);
    let d = shorten(&f, k); stats.tests += 1;
    if let Some(model) = exact_sat(&d, n, fixed_mask, fixed_values) { return Some(model); }
    for branch in 0..f.count {
        if d.length[branch] == 0 { continue; }
        stats.branches += 1;
        let (mut next_mask, mut next_values) = (fixed_mask, fixed_values);
        let mut conflict = false;
        for j in 0..d.length[branch] {
            let lit = d.literal[branch * MAX_VARS + j] as i32;
            let bit = 1u32 << (if lit > 0 { lit - 1 } else { -lit - 1 });
            let value = if lit < 0 { bit } else { 0 };
            if next_mask & bit != 0 && next_values & bit != value { conflict = true; break; }
            next_mask |= bit; next_values = (next_values & !bit) | value;
        }
        if conflict || next_mask == fixed_mask { continue; }
        let mut child = Formula { count: 0, length: [0; MAX_CLAUSES], literal: [0; MAX_LITS] };
        let newly_fixed = next_mask & !fixed_mask;
        for c in 0..f.count {
            let source = if c < branch { &d } else { &f };
            let mut satisfied = false; let mut kept = 0;
            for j in 0..source.length[c] {
                let lit = source.literal[c * MAX_VARS + j] as i32;
                let bit = 1u32 << (if lit > 0 { lit - 1 } else { -lit - 1 });
                if newly_fixed & bit != 0 {
                    let truth = next_values & bit != 0;
                    if (lit > 0 && truth) || (lit < 0 && !truth) { satisfied = true; break; }
                } else { child.literal[child.count * MAX_VARS + kept] = lit as i8; kept += 1; }
            }
            if !satisfied { child.length[child.count] = kept; child.count += 1; }
        }
        if let Some(model) = solve(child, n, k, next_mask, next_values, depth + 1, stats) { return Some(model); }
    }
    None
}

#[no_mangle]
pub unsafe extern "C" fn procedure_s_general_cnf_sat(input: *const i64, length: usize,
                                                       output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 3 || length > 39 { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let (n0, m0, k0) = (values[0], values[1], values[2]);
    if !(1..=MAX_VARS as i64).contains(&n0) || !(0..=MAX_CLAUSES as i64).contains(&m0) || k0 < 1 || k0 > n0 { return -1; }
    let (n, m, k) = (n0 as usize, m0 as usize, k0 as usize);
    let mut f = Formula { count: m, length: [0; MAX_CLAUSES], literal: [0; MAX_LITS] };
    let mut at = 3; let mut seen_clause;
    for c in 0..m {
        if at >= length || values[at] < 1 || values[at] > n0 { return -1; }
        let count = values[at] as usize; at += 1;
        if at + count > length { return -1; }
        seen_clause = 0u32; f.length[c] = count;
        for j in 0..count {
            let value = values[at]; at += 1;
            if value == 0 || value > n0 || value < -n0 { return -1; }
            let lit = value as i32; let bit = 1u32 << (if lit > 0 { lit - 1 } else { -lit - 1 });
            if seen_clause & bit != 0 { return -1; }
            seen_clause |= bit; f.literal[c * MAX_VARS + j] = lit as i8;
        }
    }
    if at != length { return -1; }
    let mut stats = Stats::default();
    let model = solve(f, n, k, 0, 0, 0, &mut stats);
    if output.is_null() || capacity < 48 { return -2; }
    let dst = std::slice::from_raw_parts_mut(output, 48);
    put_i64(dst, 0, if model.is_some() { 1 } else { 0 }); put_i64(dst, 1, model.unwrap_or(0) as i64);
    put_i64(dst, 2, stats.calls); put_i64(dst, 3, stats.tests); put_i64(dst, 4, stats.branches); put_i64(dst, 5, stats.max_depth);
    48
}
