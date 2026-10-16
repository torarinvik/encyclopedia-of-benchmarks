const MAX_VARIABLES: usize = 5;
const MAX_CLAUSES: usize = 10;
const MAX_CLAUSE_LENGTH: usize = 5;
const MAX_INPUT_LENGTH: usize = 2 + MAX_CLAUSES * (1 + MAX_CLAUSE_LENGTH);

fn dpll(pos: &[u8; MAX_CLAUSES], neg: &[u8; MAX_CLAUSES], variable_count: usize,
        clause_count: usize, mut assigned: u8, mut truth: u8) -> bool {
    let universe = ((1_u16 << variable_count) - 1) as u8;
    loop {
        let mut changed = false;
        let mut all_satisfied = true;
        for clause in 0..clause_count {
            let (p, n) = (pos[clause], neg[clause]);
            if p & n != 0 || p & truth != 0 || n & (assigned & !truth) != 0 { continue; }
            all_satisfied = false;
            let open = (p | n) & universe & !assigned;
            if open == 0 { return false; }
            if open & (open - 1) == 0 {
                if p & open != 0 { truth |= open; } else { truth &= !open; }
                assigned |= open;
                changed = true;
                break;
            }
        }
        if all_satisfied { return true; }
        if changed { continue; }
        let (mut positive_occurrences, mut negative_occurrences) = (0_u8, 0_u8);
        for clause in 0..clause_count {
            let (p, n) = (pos[clause], neg[clause]);
            if p & n != 0 || p & truth != 0 || n & (assigned & !truth) != 0 { continue; }
            let open = (p | n) & universe & !assigned;
            positive_occurrences |= p & open;
            negative_occurrences |= n & open;
        }
        let pure_true = positive_occurrences & !negative_occurrences;
        let pure_false = negative_occurrences & !positive_occurrences;
        let pure = pure_true | pure_false;
        if pure != 0 {
            truth = (truth | pure_true) & !pure_false;
            assigned |= pure;
            continue;
        }
        break;
    }
    for variable in 0..variable_count {
        let bit = 1_u8 << variable;
        if assigned & bit == 0 {
            return dpll(pos, neg, variable_count, clause_count, assigned | bit, truth | bit)
                || dpll(pos, neg, variable_count, clause_count, assigned | bit, truth & !bit);
        }
    }
    false
}

#[no_mangle]
pub unsafe extern "C" fn davis_putnam_logemann_loveland(values: *const i64, length: usize) -> i64 {
    if values.is_null() || length < 2 || length > MAX_INPUT_LENGTH { return -1; }
    let values = std::slice::from_raw_parts(values, length);
    let (variable_arg, clause_arg) = (values[0], values[1]);
    if !(0..=MAX_VARIABLES as i64).contains(&variable_arg) || !(0..=MAX_CLAUSES as i64).contains(&clause_arg) { return -1; }
    let (variable_count, clause_count) = (variable_arg as usize, clause_arg as usize);
    let mut positive = [0_u8; MAX_CLAUSES];
    let mut negative = [0_u8; MAX_CLAUSES];
    let mut position = 2;
    for clause in 0..clause_count {
        if position >= length { return -1; }
        let literal_count = values[position];
        position += 1;
        if !(0..=MAX_CLAUSE_LENGTH as i64).contains(&literal_count) || literal_count as usize > length - position { return -1; }
        for _ in 0..literal_count {
            let literal = values[position];
            position += 1;
            if literal == 0 || literal < -(variable_count as i64) || literal > variable_count as i64 { return -1; }
            let bit = 1_u8 << (literal.unsigned_abs() as usize - 1);
            if literal > 0 { positive[clause] |= bit; } else { negative[clause] |= bit; }
        }
    }
    if position != length { return -1; }
    if dpll(&positive, &negative, variable_count, clause_count, 0, 0) { 1 } else { 0 }
}
