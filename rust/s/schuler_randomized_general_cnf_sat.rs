const MAX_N: usize = 6;
const MAX_M: usize = 4;
const MAX_CALLS: usize = MAX_N + 1;
const MAX_INPUT: usize = 122;

#[derive(Default)]
struct Stats {
    calls: i64,
    unit_forces: i64,
    random_guesses: i64,
    max_depth: i64,
}

fn prefix_size(clauses: usize) -> usize {
    (usize::BITS - clauses.leading_zeros()) as usize + 1
}

fn lit_true(literal: i64, value: i8) -> bool {
    if literal > 0 { value == 1 } else { value == 0 }
}

fn ppz(
    n: usize,
    m: usize,
    formula: &[[i64; MAX_N]; MAX_M],
    lengths: &[usize; MAX_M],
    fixed: &[i8; MAX_N],
    permutation: &[i64; MAX_N],
    bits: &[i64; MAX_N],
    stats: &mut Stats,
) -> (bool, [i8; MAX_N]) {
    let mut active = [0usize; MAX_N];
    let mut active_count = 0usize;
    let mut local = [-1i8; MAX_N];
    for &value in permutation.iter().take(n) {
        let variable = value as usize - 1;
        if fixed[variable] < 0 {
            active[active_count] = variable;
            active_count += 1;
        }
    }
    let mut work = *formula;
    let mut work_lengths = *lengths;
    for offset in 0..active_count {
        let variable = active[offset];
        let positive_unit = (0..m).any(|clause| {
            work_lengths[clause] == 1 && work[clause][0] == variable as i64 + 1
        });
        let negative_unit = (0..m).any(|clause| {
            work_lengths[clause] == 1 && work[clause][0] == -(variable as i64 + 1)
        });
        let value: i8;
        if positive_unit {
            value = 1;
            stats.unit_forces += 1;
        } else if negative_unit {
            value = 0;
            stats.unit_forces += 1;
        } else {
            value = bits[offset] as i8;
            stats.random_guesses += 1;
        }
        local[variable] = value;

        let mut next = [[0i64; MAX_N]; MAX_M];
        let mut next_lengths = [0usize; MAX_M];
        let mut next_m = 0usize;
        for clause in 0..m {
            let mut satisfied = false;
            let mut out_length = 0usize;
            for item in 0..work_lengths[clause] {
                let literal = work[clause][item];
                if literal.unsigned_abs() as usize - 1 != variable {
                    next[next_m][out_length] = literal;
                    out_length += 1;
                } else if lit_true(literal, value) {
                    satisfied = true;
                    break;
                }
            }
            if !satisfied {
                next_lengths[next_m] = out_length;
                next_m += 1;
            }
        }
        work = next;
        work_lengths = next_lengths;
        m = next_m;
    }
    let success = !(0..m).any(|clause| work_lengths[clause] == 0);
    (success, local)
}

fn restrict_formula(
    formula: &[[i64; MAX_N]; MAX_M],
    lengths: &[usize; MAX_M],
    m: usize,
    assignment: &[i8; MAX_N],
) -> ([[i64; MAX_N]; MAX_M], [usize; MAX_M], usize) {
    let mut next = [[0i64; MAX_N]; MAX_M];
    let mut next_lengths = [0usize; MAX_M];
    let mut next_m = 0usize;
    for clause in 0..m {
        let mut satisfied = false;
        let mut out_length = 0usize;
        for item in 0..lengths[clause] {
            let literal = formula[clause][item];
            let value = assignment[literal.unsigned_abs() as usize - 1];
            if value < 0 {
                next[next_m][out_length] = literal;
                out_length += 1;
            } else if lit_true(literal, value) {
                satisfied = true;
                break;
            }
        }
        if !satisfied {
            next_lengths[next_m] = out_length;
            next_m += 1;
        }
    }
    (next, next_lengths, next_m)
}

fn put_i64(output: &mut [u8], word: usize, value: i64) {
    output[word * 8..word * 8 + 8].copy_from_slice(&value.to_le_bytes());
}

#[no_mangle]
pub unsafe extern "C" fn schuler_randomized_general_cnf_sat(
    input: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if input.is_null() || length < 2 || length > MAX_INPUT { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let (n0, m0) = (values[0], values[1]);
    if !(1..=MAX_N as i64).contains(&n0) || !(1..=MAX_M as i64).contains(&m0) { return -1; }
    let n = n0 as usize;
    let original_m = m0 as usize;
    let mut formula = [[0i64; MAX_N]; MAX_M];
    let mut lengths = [0usize; MAX_M];
    let mut position = 2usize;
    for clause in 0..original_m {
        if position >= length { return -1; }
        let count = values[position];
        position += 1;
        if count < 1 || count > n0 || position + count as usize > length { return -1; }
        let mut seen = [false; MAX_N];
        lengths[clause] = count as usize;
        for item in 0..lengths[clause] {
            let literal = values[position];
            position += 1;
            if literal == 0 || literal < -n0 || literal > n0 { return -1; }
            let variable = literal.unsigned_abs() as usize - 1;
            if seen[variable] { return -1; }
            seen[variable] = true;
            formula[clause][item] = literal;
        }
    }

    let mut permutations = [[0i64; MAX_N]; MAX_CALLS];
    let mut random_bits = [[0i64; MAX_N]; MAX_CALLS];
    let mut choices = [0usize; MAX_CALLS];
    for call in 0..=n {
        let mut seen = [false; MAX_N];
        for item in 0..n {
            if position >= length { return -1; }
            let value = values[position];
            position += 1;
            if value < 1 || value > n0 || seen[value as usize - 1] { return -1; }
            seen[value as usize - 1] = true;
            permutations[call][item] = value;
        }
        for item in 0..n {
            if position >= length || !(values[position] == 0 || values[position] == 1) { return -1; }
            random_bits[call][item] = values[position];
            position += 1;
        }
        if position >= length { return -1; }
        let choice = values[position];
        position += 1;
        if choice < 0 || choice >= m0 { return -1; }
        choices[call] = choice as usize;
    }
    if position != length { return -1; }

    let mut fixed = [-1i8; MAX_N];
    let mut current = formula;
    let mut current_lengths = lengths;
    let mut current_m = original_m;
    let mut stats = Stats::default();
    let mut found = false;
    let mut mask = 0i64;
    let mut depth = 0usize;
    loop {
        stats.calls += 1;
        stats.max_depth = stats.max_depth.max(depth as i64);
        if current_m == 0 {
            found = true;
            for variable in 0..n { if fixed[variable] == 1 { mask |= 1 << variable; } }
            break;
        }
        let k = prefix_size(current_m);
        let mut shortened = [[0i64; MAX_N]; MAX_M];
        let mut short_lengths = [0usize; MAX_M];
        for clause in 0..current_m {
            short_lengths[clause] = current_lengths[clause].min(k);
            shortened[clause][..short_lengths[clause]]
                .copy_from_slice(&current[clause][..short_lengths[clause]]);
        }
        let (success, local) = ppz(n, current_m, &shortened, &short_lengths, &fixed,
                                   &permutations[depth], &random_bits[depth], &mut stats);
        if success {
            found = true;
            for variable in 0..n {
                if fixed[variable] == 1 || (fixed[variable] < 0 && local[variable] == 1) {
                    mask |= 1 << variable;
                }
            }
            break;
        }
        let mut eligible = [0usize; MAX_M];
        let mut eligible_count = 0usize;
        for clause in 0..current_m {
            if short_lengths[clause] == k { eligible[eligible_count] = clause; eligible_count += 1; }
        }
        if eligible_count == 0 { break; }
        if choices[depth] >= eligible_count { return -1; }
        let selected = eligible[choices[depth]];
        let mut next_fixed = fixed;
        for item in 0..k {
            let literal = shortened[selected][item];
            next_fixed[literal.unsigned_abs() as usize - 1] = if literal > 0 { 0 } else { 1 };
        }
        let (next, next_lengths, next_m) = restrict_formula(&current, &current_lengths, current_m, &next_fixed);
        current = next;
        current_lengths = next_lengths;
        current_m = next_m;
        fixed = next_fixed;
        depth += 1;
        if depth > n { return -1; }
    }
    if !found { mask = 0; }
    let staged = [found as i64, mask, stats.calls, stats.unit_forces,
                  stats.random_guesses, stats.max_depth];
    if output.is_null() || capacity < 48 { return -2; }
    let output_bytes = std::slice::from_raw_parts_mut(output, 48);
    for word in 0..6 { put_i64(output_bytes, word, staged[word]); }
    48
}
