module ppsz_k_sat_trace

const max_n = 8
const max_clauses = 12
const max_input = 54
const max_output = 72

fn put_i64(mut output &u8, offset int, value i64) {
    bits := u64(value)
    for byte in 0 .. 8 { unsafe { output[offset + byte] = u8((bits >> (8 * byte)) & 255) } }
}
fn fixed_mask(mask0 int, assigned [max_n]int, n int) int {
    mut mask := mask0
    for i in 0 .. n { if assigned[i] >= 0 { if assigned[i] == 1 { mask |= 1 << i } else { mask &= ~(1 << i) } } }
    return mask
}
fn clause_true(clauses [max_clauses * 3]i64, clause_id int, mask int) bool {
    for j in 0 .. 3 {
        lit := clauses[3 * clause_id + j]; variable := int(if lit > 0 { lit } else { -lit }) - 1; bit := (mask >> variable) & 1
        if (lit > 0 && bit == 1) || (lit < 0 && bit == 0) { return true }
    }
    return false
}
fn selected_true(clauses [max_clauses * 3]i64, m int, subset int, mask int) bool {
    for i in 0 .. m { if (subset & (1 << i)) != 0 && !clause_true(clauses, i, mask) { return false } }
    return true
}
fn popcount(value0 int) int {
    mut value := value0; mut count := 0
    for value > 0 { count += value & 1; value >>= 1 }
    return count
}
fn current_sat(n int, m int, clauses [max_clauses * 3]i64, assigned [max_n]int) bool {
    for mask in 0 .. (1 << n) { if selected_true(clauses, m, (1 << m) - 1, fixed_mask(mask, assigned, n)) { return true } }
    return false
}
fn find_force(n int, m int, clauses [max_clauses * 3]i64, assigned [max_n]int) int {
    if !current_sat(n, m, clauses, assigned) { return -1 }
    mut threshold := 0
    for (1 << (threshold + 1)) <= n { threshold++ }
    mut implied := [max_n]int{}
    for i in 0 .. max_n { implied[i] = -1 }
    for subset in 1 .. (1 << m) {
        if popcount(subset) > threshold { continue }
        mut zero := [max_n]bool{}; mut one := [max_n]bool{}
        for mask in 0 .. (1 << n) {
            full := fixed_mask(mask, assigned, n)
            if selected_true(clauses, m, subset, full) {
                for x in 0 .. n { if assigned[x] < 0 { if ((full >> x) & 1) == 1 { one[x] = true } else { zero[x] = true } } }
            }
        }
        for x in 0 .. n { if assigned[x] < 0 && zero[x] != one[x] && implied[x] < 0 { implied[x] = if one[x] { 1 } else { 0 } } }
    }
    for x in 0 .. n { if implied[x] >= 0 { return 2 * x + implied[x] } }
    return -1
}

@[export: 'ppsz_k_sat_trace']
pub fn ppsz_k_sat_trace(input &i64, length usize, mut output &u8, capacity usize) i64 {
    if input == nil || length < 2 || length > max_input { return -1 }
    n64 := unsafe { input[0] }; m64 := unsafe { input[1] }
    if n64 < 3 || n64 > max_n || m64 < 0 || m64 > max_clauses { return -1 }
    n := int(n64); m := int(m64)
    if length != usize(2 + 3 * m + 2 * n) { return -1 }
    mut clauses := [max_clauses * 3]i64{}
    for i in 0 .. m {
        mut seen := [max_n]bool{}
        for j in 0 .. 3 {
            lit := unsafe { input[2 + 3 * i + j] }
            if lit == 0 || lit < -n64 || lit > n64 { return -1 }
            variable := int(if lit > 0 { lit } else { -lit }) - 1
            if seen[variable] { return -1 }
            seen[variable] = true; clauses[3 * i + j] = lit
        }
    }
    start := 2 + 3 * m
    mut order := [max_n]int{}; mut beta := [max_n]int{}; mut assigned := [max_n]int{}; mut seen_var := [max_n]bool{}
    for i in 0 .. max_n { assigned[i] = -1 }
    for i in 0 .. n {
        x := unsafe { input[start + i] }
        if x < 0 || x >= n64 || seen_var[int(x)] { return -1 }
        order[i] = int(x); seen_var[int(x)] = true
    }
    for i in 0 .. n { bit := unsafe { input[start + n + i] }; if bit != 0 && bit != 1 { return -1 }; beta[i] = int(bit) }
    for step in 0 .. n {
        for {
            encoded := find_force(n, m, clauses, assigned)
            if encoded < 0 { break }
            variable := encoded / 2; assigned[variable] = encoded % 2
        }
        var_id := order[step]
        if assigned[var_id] < 0 { assigned[var_id] = beta[var_id] }
    }
    mut mask := 0
    for i in 0 .. n { if assigned[i] == 1 { mask |= 1 << i } }
    verdict := i64(0); if selected_true(clauses, m, (1 << m) - 1, mask) { verdict = 1 }
    bytes := 8 * (n + 1)
    if output == nil || capacity < usize(bytes) { return -2 }
    mut staged := [max_output]u8{}
    put_i64(mut &staged[0], 0, verdict)
    for i in 0 .. n { put_i64(mut &staged[0], 8 * (i + 1), i64(assigned[i])) }
    unsafe { for i in 0 .. bytes { output[i] = staged[i] } }
    return i64(bytes)
}
