#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_states = 4, max_actions = 3;
constexpr std::size_t max_records = max_states * max_actions;
struct Fraction { std::int64_t numerator{}, denominator{1}; };

std::uint64_t gcd_u64(std::uint64_t a, std::uint64_t b) noexcept {
    while (b != 0) { const auto remainder = a % b; a = b; b = remainder; }
    return a;
}

Fraction reduce_fraction(std::int64_t numerator, std::int64_t denominator) noexcept {
    const auto magnitude = numerator < 0 ? static_cast<std::uint64_t>(-numerator)
                                          : static_cast<std::uint64_t>(numerator);
    const auto divisor = gcd_u64(magnitude, static_cast<std::uint64_t>(denominator));
    return {numerator / static_cast<std::int64_t>(divisor), denominator / static_cast<std::int64_t>(divisor)};
}

std::int64_t power_i64(std::int64_t base, std::size_t exponent) noexcept {
    std::int64_t result = 1;
    while (exponent-- != 0) result *= base;
    return result;
}

Fraction extend_value(std::int64_t reward, Fraction successor, std::int64_t p, std::int64_t q) noexcept {
    return reduce_fraction(reward * successor.denominator * q + p * successor.numerator,
                           successor.denominator * q);
}

void evaluate_policy(std::size_t states, std::size_t actions, std::int64_t p, std::int64_t q,
                     const std::array<std::int64_t, max_records>& rewards,
                     const std::array<std::int64_t, max_records>& successors,
                     const std::array<std::size_t, max_states>& policy,
                     std::array<Fraction, max_states>& values) noexcept {
    for (std::size_t start = 0; start < states; ++start) {
        std::array<int, max_states> first_seen{-1, -1, -1, -1};
        std::array<std::size_t, max_states> path{};
        std::size_t path_length = 0, current = start;
        while (first_seen[current] < 0) {
            first_seen[current] = static_cast<int>(path_length);
            path[path_length++] = current;
            current = static_cast<std::size_t>(successors[path[path_length - 1] * actions + policy[path[path_length - 1]]]);
        }
        const auto cycle_start = static_cast<std::size_t>(first_seen[current]);
        const auto cycle_length = path_length - cycle_start;
        std::int64_t cycle_numerator = 0;
        for (std::size_t j = 0; j < cycle_length; ++j) {
            const auto state = path[cycle_start + j];
            cycle_numerator += rewards[state * actions + policy[state]]
                * power_i64(p, j) * power_i64(q, cycle_length - j);
        }
        values[path[cycle_start]] = reduce_fraction(cycle_numerator,
            power_i64(q, cycle_length) - power_i64(p, cycle_length));

        for (std::size_t j = path_length; j > cycle_start + 1; --j) {
            const auto index = j - 1;
            const auto state = path[index];
            const auto next_state = index + 1 < path_length ? path[index + 1] : path[cycle_start];
            values[state] = extend_value(rewards[state * actions + policy[state]], values[next_state], p, q);
        }
        for (std::size_t j = cycle_start; j > 0; --j) {
            const auto index = j - 1;
            const auto state = path[index];
            values[state] = extend_value(rewards[state * actions + policy[state]], values[path[index + 1]], p, q);
        }
    }
}

std::size_t improve_policy(std::size_t states, std::size_t actions, std::int64_t p, std::int64_t q,
                           const std::array<std::int64_t, max_records>& rewards,
                           const std::array<std::int64_t, max_records>& successors,
                           const std::array<Fraction, max_states>& values,
                           std::array<std::size_t, max_states>& policy) noexcept {
    std::size_t changed = 0;
    for (std::size_t state = 0; state < states; ++state) {
        std::size_t best_action = 0;
        const auto best_next = static_cast<std::size_t>(successors[state * actions]);
        auto best = extend_value(rewards[state * actions], values[best_next], p, q);
        for (std::size_t action = 1; action < actions; ++action) {
            const auto index = state * actions + action;
            const auto candidate = extend_value(rewards[index], values[static_cast<std::size_t>(successors[index])], p, q);
            if (candidate.numerator * best.denominator > best.numerator * candidate.denominator) {
                best_action = action;
                best = candidate;
            }
        }
        if (policy[state] != best_action) { policy[state] = best_action; ++changed; }
    }
    return changed;
}

void write_i64_le(std::uint8_t* output, std::size_t offset, std::int64_t value) noexcept {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>(bits >> (byte * 8));
}
}

extern "C" std::int64_t mdp_policy_iteration(const std::int64_t* input, std::size_t length,
                                              std::uint8_t* output, std::size_t capacity) noexcept {
    if (input == nullptr || length < 4 || length > 28) return -1;
    const auto s_value = input[0], a_value = input[1], p = input[2], q = input[3];
    if (s_value < 1 || s_value > static_cast<std::int64_t>(max_states) ||
        a_value < 1 || a_value > static_cast<std::int64_t>(max_actions) || q < 1 || q > 4 || p < 0 || p >= q) return -1;
    const auto states = static_cast<std::size_t>(s_value), actions = static_cast<std::size_t>(a_value);
    if (length != 4 + 2 * states * actions) return -1;
    std::array<std::int64_t, max_records> rewards{}, successors{};
    for (std::size_t i = 0; i < states * actions; ++i) {
        const auto reward = input[4 + 2 * i], successor = input[5 + 2 * i];
        if (reward < -20 || reward > 20 || successor < 0 || successor >= s_value) return -1;
        rewards[i] = reward;
        successors[i] = successor;
    }
    std::array<std::size_t, max_states> policy{};
    std::array<Fraction, max_states> values{};
    std::size_t policy_count = 1;
    for (std::size_t i = 0; i < states; ++i) policy_count *= actions;
    bool stable = false;
    for (std::size_t iteration = 0; iteration <= policy_count; ++iteration) {
        evaluate_policy(states, actions, p, q, rewards, successors, policy, values);
        if (improve_policy(states, actions, p, q, rewards, successors, values, policy) == 0) {
            stable = true;
            break;
        }
    }
    if (!stable) return -1;
    std::array<std::int64_t, 1 + 3 * max_states> words{};
    words[0] = static_cast<std::int64_t>(states);
    for (std::size_t state = 0; state < states; ++state) {
        words[1 + state] = static_cast<std::int64_t>(policy[state]);
        words[1 + states + 2 * state] = values[state].numerator;
        words[2 + states + 2 * state] = values[state].denominator;
    }
    const auto bytes = (1 + 3 * states) * 8;
    if (output == nullptr || capacity < bytes) return -2;
    for (std::size_t i = 0; i < 1 + 3 * states; ++i) write_i64_le(output, i * 8, words[i]);
    return static_cast<std::int64_t>(bytes);
}
