module mdp_policy_iteration;

const usz MAX_STATES = 4;
const usz MAX_ACTIONS = 3;
const usz MAX_RECORDS = 12;
const usz MAX_OUTPUT_WORDS = 13;

struct Fraction { long numerator; long denominator; }

fn ulong gcd_u64(ulong a, ulong b) {
    while (b != 0) { ulong remainder = a % b; a = b; b = remainder; }
    return a;
}

fn Fraction reduce_fraction(long numerator, long denominator) {
    ulong magnitude = numerator < 0 ? (ulong)(-numerator) : (ulong)numerator;
    ulong divisor = gcd_u64(magnitude, (ulong)denominator);
    if (divisor == 0) divisor = 1;
    return Fraction{numerator / (long)divisor, denominator / (long)divisor};
}

fn long power_i64(long base, usz exponent) {
    long result = 1;
    while (exponent > 0) { result *= base; exponent--; }
    return result;
}

fn Fraction extend_value(long reward, Fraction successor, long p, long q) {
    return reduce_fraction(reward * successor.denominator * q + p * successor.numerator,
                           successor.denominator * q);
}

fn void evaluate_policy(usz states, usz actions, long p, long q, long* rewards,
    long* successors, usz* policy, Fraction* values) {
    for (usz start = 0; start < states; start++) {
        int[MAX_STATES] first_seen = {-1, -1, -1, -1};
        usz[MAX_STATES] path = zeroed;
        usz path_length = 0;
        usz current = start;
        while (first_seen[current] < 0) {
            first_seen[current] = (int)path_length;
            path[path_length++] = current;
            current = (usz)successors[path[path_length - 1] * actions + policy[path[path_length - 1]]];
        }
        usz cycle_start = (usz)first_seen[current];
        usz cycle_length = path_length - cycle_start;
        long cycle_numerator = 0;
        for (usz j = 0; j < cycle_length; j++) {
            usz state = path[cycle_start + j];
            long reward = rewards[state * actions + policy[state]];
            cycle_numerator += reward * power_i64(p, j) * power_i64(q, cycle_length - j);
        }
        values[path[cycle_start]] = reduce_fraction(cycle_numerator,
            power_i64(q, cycle_length) - power_i64(p, cycle_length));
        for (usz j = path_length; j > cycle_start + 1; j--) {
            usz index = j - 1;
            usz state = path[index];
            usz next_state = index + 1 < path_length ? path[index + 1] : path[cycle_start];
            values[state] = extend_value(rewards[state * actions + policy[state]], values[next_state], p, q);
        }
        for (usz j = cycle_start; j > 0; j--) {
            usz index = j - 1;
            usz state = path[index];
            values[state] = extend_value(rewards[state * actions + policy[state]], values[path[index + 1]], p, q);
        }
    }
}

fn usz improve_policy(usz states, usz actions, long p, long q, long* rewards,
    long* successors, Fraction* values, usz* policy) {
    usz changed = 0;
    for (usz state = 0; state < states; state++) {
        usz best_action = 0;
        usz best_next = (usz)successors[state * actions];
        Fraction best = extend_value(rewards[state * actions], values[best_next], p, q);
        for (usz action = 1; action < actions; action++) {
            usz index = state * actions + action;
            Fraction candidate = extend_value(rewards[index], values[(usz)successors[index]], p, q);
            if (candidate.numerator * best.denominator > best.numerator * candidate.denominator) {
                best_action = action;
                best = candidate;
            }
        }
        if (policy[state] != best_action) { policy[state] = best_action; changed++; }
    }
    return changed;
}

fn void write_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) output[offset + byte] = (char)(bits >> (byte * 8));
}

fn long mdp_policy_iteration(long* input, usz length, char* output,
    usz output_capacity) @export("mdp_policy_iteration") {
    if (input == null || length < 4 || length > 28) return -1;
    long states_value = input[0], actions_value = input[1], p = input[2], q = input[3];
    if (states_value < 1 || states_value > (long)MAX_STATES || actions_value < 1 || actions_value > (long)MAX_ACTIONS ||
        q < 1 || q > 4 || p < 0 || p >= q) return -1;
    usz states = (usz)states_value, actions = (usz)actions_value;
    if (length != 4 + 2 * states * actions) return -1;
    long[MAX_RECORDS] rewards = zeroed;
    long[MAX_RECORDS] successors = zeroed;
    for (usz i = 0; i < states * actions; i++) {
        long reward = input[4 + 2 * i], successor = input[5 + 2 * i];
        if (reward < -20 || reward > 20 || successor < 0 || successor >= states_value) return -1;
        rewards[i] = reward;
        successors[i] = successor;
    }
    usz[MAX_STATES] policy = zeroed;
    Fraction[MAX_STATES] values = zeroed;
    for (usz state = 0; state < MAX_STATES; state++) values[state].denominator = 1;
    usz policy_count = 1;
    for (usz i = 0; i < states; i++) policy_count *= actions;
    bool stable = false;
    for (usz iteration = 0; iteration <= policy_count; iteration++) {
        evaluate_policy(states, actions, p, q, &rewards[0], &successors[0], &policy[0], &values[0]);
        if (improve_policy(states, actions, p, q, &rewards[0], &successors[0], &values[0], &policy[0]) == 0) {
            stable = true;
            break;
        }
    }
    if (!stable) return -1;
    long[MAX_OUTPUT_WORDS] words = zeroed;
    words[0] = (long)states;
    for (usz state = 0; state < states; state++) {
        words[1 + state] = (long)policy[state];
        words[1 + states + 2 * state] = values[state].numerator;
        words[2 + states + 2 * state] = values[state].denominator;
    }
    usz output_bytes = (1 + 3 * states) * 8;
    if (output == null || output_capacity < output_bytes) return -2;
    for (usz i = 0; i < 1 + 3 * states; i++) write_i64_le(output, i * 8, words[i]);
    return (long)output_bytes;
}
