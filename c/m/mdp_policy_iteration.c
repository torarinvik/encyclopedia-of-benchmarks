#include <stddef.h>
#include <stdint.h>

#define MAX_STATES 4
#define MAX_ACTIONS 3
#define MAX_RECORDS (MAX_STATES * MAX_ACTIONS)
#define MAX_OUTPUT_WORDS (1 + 3 * MAX_STATES)

typedef struct { int64_t numerator, denominator; } Fraction;

static uint64_t gcd_u64(uint64_t a, uint64_t b) {
    while (b != 0) { uint64_t r = a % b; a = b; b = r; }
    return a;
}

static Fraction reduce_fraction(int64_t numerator, int64_t denominator) {
    uint64_t magnitude = numerator < 0 ? (uint64_t)(-numerator) : (uint64_t)numerator;
    uint64_t divisor = gcd_u64(magnitude, (uint64_t)denominator);
    if (divisor == 0) divisor = 1;
    return (Fraction){numerator / (int64_t)divisor, denominator / (int64_t)divisor};
}

static int64_t power_i64(int64_t base, size_t exponent) {
    int64_t result = 1;
    while (exponent-- != 0) result *= base;
    return result;
}

static Fraction extend_value(int64_t reward, Fraction successor, int64_t p, int64_t q) {
    return reduce_fraction(reward * successor.denominator * q + p * successor.numerator,
                           successor.denominator * q);
}

static Fraction action_value(int64_t reward, Fraction successor, int64_t p, int64_t q) {
    return extend_value(reward, successor, p, q);
}

static void evaluate_policy(size_t states, size_t actions, int64_t p, int64_t q,
                           const int64_t rewards[MAX_RECORDS],
                           const int64_t successors[MAX_RECORDS],
                           const size_t policy[MAX_STATES], Fraction values[MAX_STATES]) {
    for (size_t start = 0; start < states; ++start) {
        int first_seen[MAX_STATES] = {-1, -1, -1, -1};
        size_t path[MAX_STATES];
        size_t path_length = 0;
        size_t current = start;
        while (first_seen[current] < 0) {
            first_seen[current] = (int)path_length;
            path[path_length++] = current;
            current = (size_t)successors[path[path_length - 1] * actions + policy[path[path_length - 1]]];
        }
        size_t cycle_start = (size_t)first_seen[current];
        size_t cycle_length = path_length - cycle_start;
        int64_t cycle_numerator = 0;
        for (size_t j = 0; j < cycle_length; ++j) {
            size_t state = path[cycle_start + j];
            int64_t reward = rewards[state * actions + policy[state]];
            cycle_numerator += reward * power_i64(p, j) * power_i64(q, cycle_length - j);
        }
        Fraction cycle_value = reduce_fraction(cycle_numerator,
            power_i64(q, cycle_length) - power_i64(p, cycle_length));
        values[path[cycle_start]] = cycle_value;

        for (size_t j = path_length; j > cycle_start + 1; --j) {
            size_t index = j - 1;
            size_t state = path[index];
            size_t next_state = index + 1 < path_length ? path[index + 1] : path[cycle_start];
            values[state] = extend_value(rewards[state * actions + policy[state]], values[next_state], p, q);
        }
        for (size_t j = cycle_start; j > 0; --j) {
            size_t index = j - 1;
            size_t state = path[index];
            values[state] = extend_value(rewards[state * actions + policy[state]], values[path[index + 1]], p, q);
        }
    }
}

static size_t greedy_policy(size_t states, size_t actions, int64_t p, int64_t q,
                            const int64_t rewards[MAX_RECORDS],
                            const int64_t successors[MAX_RECORDS],
                            const Fraction values[MAX_STATES], size_t policy[MAX_STATES]) {
    size_t changed = 0;
    for (size_t state = 0; state < states; ++state) {
        size_t best_action = 0;
        size_t best_next = (size_t)successors[state * actions];
        Fraction best = action_value(rewards[state * actions], values[best_next], p, q);
        for (size_t action = 1; action < actions; ++action) {
            size_t index = state * actions + action;
            Fraction candidate = action_value(rewards[index], values[(size_t)successors[index]], p, q);
            if (candidate.numerator * best.denominator > best.numerator * candidate.denominator) {
                best_action = action;
                best = candidate;
            }
        }
        if (policy[state] != best_action) { policy[state] = best_action; ++changed; }
    }
    return changed;
}

static void write_i64_le(uint8_t *output, size_t offset, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) output[offset + byte] = (uint8_t)(bits >> (byte * 8));
}

int64_t mdp_policy_iteration(const int64_t *input, size_t length,
                             uint8_t *output, size_t capacity) {
    if (input == NULL || length < 4 || length > 28) return -1;
    int64_t states_value = input[0], actions_value = input[1], p = input[2], q = input[3];
    if (states_value < 1 || states_value > MAX_STATES || actions_value < 1 || actions_value > MAX_ACTIONS ||
        q < 1 || q > 4 || p < 0 || p >= q) return -1;
    size_t states = (size_t)states_value, actions = (size_t)actions_value;
    if (length != 4 + 2 * states * actions) return -1;
    int64_t rewards[MAX_RECORDS] = {0}, successors[MAX_RECORDS] = {0};
    for (size_t i = 0; i < states * actions; ++i) {
        int64_t reward = input[4 + 2 * i], successor = input[5 + 2 * i];
        if (reward < -20 || reward > 20 || successor < 0 || successor >= states_value) return -1;
        rewards[i] = reward;
        successors[i] = successor;
    }

    size_t policy[MAX_STATES] = {0, 0, 0, 0};
    Fraction values[MAX_STATES] = {{0, 1}, {0, 1}, {0, 1}, {0, 1}};
    size_t policy_count = 1;
    for (size_t i = 0; i < states; ++i) policy_count *= actions;
    int stable = 0;
    for (size_t iteration = 0; iteration <= policy_count; ++iteration) {
        evaluate_policy(states, actions, p, q, rewards, successors, policy, values);
        if (greedy_policy(states, actions, p, q, rewards, successors, values, policy) == 0) {
            stable = 1;
            break;
        }
    }
    if (!stable) return -1;

    int64_t words[MAX_OUTPUT_WORDS] = {0};
    words[0] = (int64_t)states;
    for (size_t state = 0; state < states; ++state) {
        words[1 + state] = (int64_t)policy[state];
        words[1 + states + 2 * state] = values[state].numerator;
        words[2 + states + 2 * state] = values[state].denominator;
    }
    size_t output_bytes = (1 + 3 * states) * 8;
    if (output == NULL || capacity < output_bytes) return -2;
    for (size_t i = 0; i < 1 + 3 * states; ++i) write_i64_le(output, i * 8, words[i]);
    return (int64_t)output_bytes;
}
