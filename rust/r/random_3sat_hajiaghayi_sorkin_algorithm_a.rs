const MAX_VARS: usize = 12;
const MAX_CLAUSES: usize = 32;
const MAX_INPUT: usize = 98;
const MAX_OUTPUT: usize = 104;

fn put(out: &mut [u8], at: usize, value: i64) {
    out[at..at + 8].copy_from_slice(&value.to_le_bytes());
}

fn reduce_by_literal(
    clauses: &mut [[i32; 3]; MAX_CLAUSES],
    lengths: &mut [usize; MAX_CLAUSES],
    active: &mut [bool; MAX_CLAUSES],
    count: usize,
    literal: i32,
) -> bool {
    for clause in 0..count {
        if !active[clause] { continue; }
        if clauses[clause][..lengths[clause]].contains(&literal) {
            active[clause] = false;
            continue;
        }
        let mut write = 0;
        for at in 0..lengths[clause] {
            let value = clauses[clause][at];
            if value != -literal {
                clauses[clause][write] = value;
                write += 1;
            }
        }
        lengths[clause] = write;
        if write == 0 { return false; }
    }
    true
}

fn choose_free_literal(
    n: usize,
    clauses: &[[i32; 3]; MAX_CLAUSES],
    lengths: &[usize; MAX_CLAUSES],
    active: &[bool; MAX_CLAUSES],
    assigned: &[i8; MAX_VARS],
) -> i32 {
    let mut positive = [0usize; MAX_VARS];
    let mut negative = [0usize; MAX_VARS];
    for clause in 0..MAX_CLAUSES {
        if !active[clause] { continue; }
        for &literal in &clauses[clause][..lengths[clause]] {
            let variable = literal.unsigned_abs() as usize - 1;
            if literal > 0 { positive[variable] += 1; }
            else { negative[variable] += 1; }
        }
    }
    for variable in 0..n {
        if assigned[variable] == 0 && (positive[variable] == 0 || negative[variable] == 0) {
            return if positive[variable] < negative[variable] {
                (variable + 1) as i32
            } else {
                -((variable + 1) as i32)
            };
        }
    }
    let mut selected = None;
    let mut best = (0usize, 0usize);
    for variable in 0..n {
        if assigned[variable] != 0 { continue; }
        let score = (positive[variable].abs_diff(negative[variable]),
                     positive[variable] + negative[variable]);
        if selected.is_none() || score > best {
            selected = Some(variable);
            best = score;
        }
    }
    let Some(variable) = selected else { return 0; };
    if positive[variable] < negative[variable] { (variable + 1) as i32 }
    else { -((variable + 1) as i32) }
}

#[no_mangle]
pub unsafe extern "C" fn random_3sat_hajiaghayi_sorkin_algorithm_a(
    values: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if values.is_null() || length < 2 || length > MAX_INPUT { return -1; }
    let input = std::slice::from_raw_parts(values, length);
    if !(3..=MAX_VARS as i64).contains(&input[0]) || input[1] < 0 || input[1] > MAX_CLAUSES as i64 { return -1; }
    let n = input[0] as usize;
    let m = input[1] as usize;
    if length != 2 + 3 * m { return -1; }

    let mut clauses = [[0i32; 3]; MAX_CLAUSES];
    let mut lengths = [0usize; MAX_CLAUSES];
    let mut active = [false; MAX_CLAUSES];
    for clause in 0..m {
        let mut seen = [false; MAX_VARS];
        for at in 0..3 {
            let raw = input[2 + 3 * clause + at];
            if raw == 0 || raw < -(n as i64) || raw > n as i64 { return -1; }
            let variable = raw.unsigned_abs() as usize - 1;
            if seen[variable] { return -1; }
            seen[variable] = true;
            clauses[clause][at] = raw as i32;
        }
        lengths[clause] = 3;
        active[clause] = true;
    }

    let mut assigned = [0i8; MAX_VARS];
    let mut assigned_count = 0;
    let mut failed = false;
    while assigned_count < n && !failed {
        let chosen = choose_free_literal(n, &clauses, &lengths, &active, &assigned);
        if chosen == 0 { failed = true; break; }
        let variable = chosen.unsigned_abs() as usize - 1;
        assigned[variable] = if chosen > 0 { 1 } else { -1 };
        assigned_count += 1;
        if !reduce_by_literal(&mut clauses, &mut lengths, &mut active, m, chosen) {
            failed = true;
            break;
        }
        while !failed {
            let unit = (0..m).find(|&clause| active[clause] && lengths[clause] == 1)
                .map(|clause| clauses[clause][0]);
            let Some(literal) = unit else { break; };
            let variable = literal.unsigned_abs() as usize - 1;
            assigned[variable] = if literal > 0 { 1 } else { -1 };
            assigned_count += 1;
            if !reduce_by_literal(&mut clauses, &mut lengths, &mut active, m, literal) {
                failed = true;
            }
        }
    }

    let bytes = 8 * (n + 1);
    if output.is_null() || capacity < bytes { return -2; }
    let mut staged = [0u8; MAX_OUTPUT];
    put(&mut staged, 0, if failed { 0 } else { 1 });
    for variable in 0..n {
        put(&mut staged, 8 * (variable + 1), assigned[variable] as i64);
    }
    std::ptr::copy_nonoverlapping(staged.as_ptr(), output, bytes);
    bytes as i64
}
