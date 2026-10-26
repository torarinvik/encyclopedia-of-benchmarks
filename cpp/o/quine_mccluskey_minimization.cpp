/* Exact bounded Quine-McCluskey prime-implicant and cover search. */
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MAX_VARIABLES = 3;
constexpr std::size_t MAX_CUBES = 27;
constexpr std::size_t MAX_STATES = 256;
constexpr std::size_t MAX_INPUT_LENGTH = 9;
constexpr unsigned INF = 99;

bool valid_cube(unsigned care, unsigned value, const std::int64_t *status,
                std::size_t size, unsigned *covered_on) noexcept {
    unsigned cover = 0;
    for (std::size_t minterm = 0; minterm < size; ++minterm) {
        if ((static_cast<unsigned>(minterm) & care) == value) {
            if (status[minterm] == 0) return false;
            if (status[minterm] == 1) cover |= 1u << minterm;
        }
    }
    if (covered_on != nullptr) *covered_on = cover;
    return cover != 0;
}

bool lexicographically_better(std::uint32_t candidate, std::uint32_t incumbent,
                              std::size_t prime_count) noexcept {
    for (std::size_t index = 0; index < prime_count; ++index) {
        const std::uint32_t bit = 1u << index;
        const bool left = (candidate & bit) != 0;
        const bool right = (incumbent & bit) != 0;
        if (left != right) return left;
    }
    return false;
}

void store_i64_le(std::uint8_t *output, std::size_t offset, std::int64_t value) noexcept {
    std::uint64_t bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = static_cast<std::uint8_t>(bits & 255);
        bits >>= 8;
    }
}
}

extern "C" std::int64_t quine_mccluskey_minimization(const std::int64_t *input,
    std::size_t length, std::uint8_t *output, std::size_t capacity) noexcept {
    if (input == nullptr || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    if (input[0] < 1 || input[0] > static_cast<std::int64_t>(MAX_VARIABLES)) return -1;
    const std::size_t n = static_cast<std::size_t>(input[0]);
    const std::size_t size = 1u << n;
    if (length != 1 + size) return -1;
    for (std::size_t minterm = 0; minterm < size; ++minterm)
        if (input[1 + minterm] < 0 || input[1 + minterm] > 2) return -1;

    unsigned care[MAX_CUBES]{}, value[MAX_CUBES]{}, cover[MAX_CUBES]{}, literals[MAX_CUBES]{};
    std::size_t prime_count = 0;
    const unsigned full = static_cast<unsigned>(size) - 1;
    for (unsigned cube_care = 0; cube_care <= full; ++cube_care) {
        for (unsigned cube_value = 0; cube_value <= full; ++cube_value) {
            if ((cube_value & ~cube_care) != 0) continue;
            unsigned on_cover = 0;
            if (!valid_cube(cube_care, cube_value, input + 1, size, &on_cover)) continue;
            bool prime = true;
            for (std::size_t variable = 0; variable < n; ++variable) {
                const unsigned bit = 1u << variable;
                if ((cube_care & bit) != 0 &&
                    valid_cube(cube_care ^ bit, cube_value & ~bit, input + 1, size, nullptr)) {
                    prime = false;
                    break;
                }
            }
            if (!prime) continue;
            care[prime_count] = cube_care;
            value[prime_count] = cube_value;
            cover[prime_count] = on_cover;
            unsigned bits = cube_care;
            while (bits != 0) { literals[prime_count] += bits & 1u; bits >>= 1; }
            ++prime_count;
        }
    }
    unsigned on_mask = 0;
    for (std::size_t minterm = 0; minterm < size; ++minterm)
        if (input[1 + minterm] == 1) on_mask |= 1u << minterm;
    const std::size_t state_count = 1u << size;
    unsigned term_cost[MAX_STATES], literal_cost[MAX_STATES];
    std::uint32_t selected[MAX_STATES];
    for (std::size_t state = 0; state < state_count; ++state) {
        term_cost[state] = INF;
        literal_cost[state] = INF;
        selected[state] = 0;
    }
    term_cost[0] = literal_cost[0] = 0;
    for (std::size_t index = 0; index < prime_count; ++index) {
        const std::uint32_t prime_bit = 1u << index;
        for (std::size_t state = state_count; state-- > 0;) {
            if (term_cost[state] == INF) continue;
            const std::size_t destination = state | cover[index];
            if (destination == state) continue;
            const unsigned new_terms = term_cost[state] + 1;
            const unsigned new_literals = literal_cost[state] + literals[index];
            const std::uint32_t new_selected = selected[state] | prime_bit;
            bool better = new_terms < term_cost[destination];
            if (new_terms == term_cost[destination]) {
                better = new_literals < literal_cost[destination];
                if (new_literals == literal_cost[destination])
                    better = lexicographically_better(new_selected, selected[destination], prime_count);
            }
            if (better) {
                term_cost[destination] = new_terms;
                literal_cost[destination] = new_literals;
                selected[destination] = new_selected;
            }
        }
    }
    const std::uint32_t chosen = selected[on_mask];
    std::size_t term_count = 0;
    for (std::size_t index = 0; index < prime_count; ++index)
        if ((chosen & (1u << index)) != 0) ++term_count;
    const std::size_t output_bytes = 8 * (1 + 2 * term_count);
    if (output == nullptr || capacity < output_bytes) return -2;
    std::size_t cursor = 0;
    store_i64_le(output, cursor++ * 8, static_cast<std::int64_t>(term_count));
    for (std::size_t index = 0; index < prime_count; ++index) {
        if ((chosen & (1u << index)) != 0) {
            store_i64_le(output, cursor++ * 8, static_cast<std::int64_t>(care[index]));
            store_i64_le(output, cursor++ * 8, static_cast<std::int64_t>(value[index]));
        }
    }
    return static_cast<std::int64_t>(output_bytes);
}
