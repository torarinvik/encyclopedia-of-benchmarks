const MAX_STATES: usize = 4;
const MAX_ACTIONS: usize = 3;
const MAX_RECORDS: usize = 12;
const MAX_OUTPUT_WORDS: usize = 13;

#[derive(Clone, Copy, Default)]
struct Fraction { numerator: i64, denominator: i64 }

struct PolicyContext {
    rewards: [i64; MAX_RECORDS],
    successors: [i64; MAX_RECORDS],
    policy: [usize; MAX_STATES],
    values: [Fraction; MAX_STATES],
}

fn gcd_u64(mut a: u64, mut b: u64) -> u64 {
    while b != 0 { let remainder = a % b; a = b; b = remainder; }
    a
}

fn reduce_fraction(numerator: i64, denominator: i64) -> Fraction {
    let magnitude = if numerator < 0 { (-numerator) as u64 } else { numerator as u64 };
    let divisor = gcd_u64(magnitude, denominator as u64);
    Fraction { numerator: numerator / divisor as i64, denominator: denominator / divisor as i64 }
}

fn power_i64(base: i64, exponent: usize) -> i64 {
    let mut result = 1i64;
    for _ in 0..exponent { result *= base; }
    result
}

fn extend_value(reward: i64, successor: Fraction, p: i64, q: i64) -> Fraction {
    reduce_fraction(reward * successor.denominator * q + p * successor.numerator,
                    successor.denominator * q)
}

fn evaluate_policy(context: &mut PolicyContext, states: usize, actions: usize, p: i64, q: i64) {
    for start in 0..states {
        let mut first_seen = [-1i32; MAX_STATES];
        let mut path = [0usize; MAX_STATES];
        let mut path_length = 0usize;
        let mut current = start;
        while first_seen[current] < 0 {
            first_seen[current] = path_length as i32;
            path[path_length] = current;
            path_length += 1;
            let state = path[path_length - 1];
            let record = state * actions + context.policy[state];
            current = context.successors[record] as usize;
        }
        let cycle_start = first_seen[current] as usize;
        let cycle_length = path_length - cycle_start;
        let mut cycle_numerator = 0i64;
        for j in 0..cycle_length {
            let state = path[cycle_start + j];
            let record = state * actions + context.policy[state];
            cycle_numerator += context.rewards[record] * power_i64(p, j) * power_i64(q, cycle_length - j);
        }
        context.values[path[cycle_start]] = reduce_fraction(cycle_numerator,
            power_i64(q, cycle_length) - power_i64(p, cycle_length));

        let mut j = path_length;
        while j > cycle_start + 1 {
            let index = j - 1;
            let state = path[index];
            let next_state = if index + 1 < path_length { path[index + 1] } else { path[cycle_start] };
            let record = state * actions + context.policy[state];
            context.values[state] = extend_value(context.rewards[record], context.values[next_state], p, q);
            j -= 1;
        }
        j = cycle_start;
        while j > 0 {
            let index = j - 1;
            let state = path[index];
            let record = state * actions + context.policy[state];
            context.values[state] = extend_value(context.rewards[record], context.values[path[index + 1]], p, q);
            j -= 1;
        }
    }
}

fn improve_policy(context: &mut PolicyContext, states: usize, actions: usize, p: i64, q: i64) -> usize {
    let mut changed = 0;
    for state in 0..states {
        let mut best_action = 0;
        let best_record = state * actions;
        let best_next = context.successors[best_record] as usize;
        let mut best = extend_value(context.rewards[best_record], context.values[best_next], p, q);
        for action in 1..actions {
            let record = state * actions + action;
            let next_state = context.successors[record] as usize;
            let candidate = extend_value(context.rewards[record], context.values[next_state], p, q);
            if candidate.numerator * best.denominator > best.numerator * candidate.denominator {
                best_action = action;
                best = candidate;
            }
        }
        if context.policy[state] != best_action {
            context.policy[state] = best_action;
            changed += 1;
        }
    }
    changed
}

fn write_i64_le(output: &mut [u8], offset: usize, value: i64) {
    output[offset..offset + 8].copy_from_slice(&value.to_le_bytes());
}

#[no_mangle]
pub unsafe extern "C" fn mdp_policy_iteration(input: *const i64, length: usize,
    output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 4 || length > 28 { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    if !(1..=MAX_STATES as i64).contains(&values[0]) || !(1..=MAX_ACTIONS as i64).contains(&values[1])
        || values[3] < 1 || values[3] > 4 || values[2] < 0 || values[2] >= values[3] { return -1; }
    let states = values[0] as usize;
    let actions = values[1] as usize;
    let p = values[2];
    let q = values[3];
    if length != 4 + 2 * states * actions { return -1; }
    let mut context = PolicyContext {
        rewards: [0; MAX_RECORDS], successors: [0; MAX_RECORDS],
        policy: [0; MAX_STATES], values: [Fraction { numerator: 0, denominator: 1 }; MAX_STATES],
    };
    for i in 0..states * actions {
        let reward = values[4 + 2 * i];
        let successor = values[5 + 2 * i];
        if !(-20..=20).contains(&reward) || successor < 0 || successor >= states as i64 { return -1; }
        context.rewards[i] = reward;
        context.successors[i] = successor;
    }
    let policy_count = actions.pow(states as u32);
    let mut stable = false;
    for _ in 0..=policy_count {
        evaluate_policy(&mut context, states, actions, p, q);
        if improve_policy(&mut context, states, actions, p, q) == 0 { stable = true; break; }
    }
    if !stable { return -1; }
    let mut words = [0i64; MAX_OUTPUT_WORDS];
    words[0] = states as i64;
    for state in 0..states {
        words[1 + state] = context.policy[state] as i64;
        words[1 + states + 2 * state] = context.values[state].numerator;
        words[2 + states + 2 * state] = context.values[state].denominator;
    }
    let output_bytes = (1 + 3 * states) * 8;
    if output.is_null() || capacity < output_bytes { return -2; }
    let output_slice = std::slice::from_raw_parts_mut(output, output_bytes);
    for i in 0..1 + 3 * states { write_i64_le(output_slice, i * 8, words[i]); }
    output_bytes as i64
}
