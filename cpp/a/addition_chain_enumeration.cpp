#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr int max_target = 31;
constexpr std::size_t output_bytes = 24;

struct Search {
    int target;
    int limit;
    std::array<int, max_target + 1> chain{};
    std::int64_t total_count = 0;
    std::int64_t brauer_count = 0;
};

void visit(Search& state, std::size_t length, bool prefix_is_brauer) {
    const int last = state.chain[length - 1];
    const int steps = static_cast<int>(length) - 1;
    if (last == state.target) {
        if (steps == state.limit) {
            ++state.total_count;
            if (prefix_is_brauer) ++state.brauer_count;
        }
        return;
    }
    const int remaining = state.limit - steps;
    if (remaining <= 0 || last * (1 << remaining) < state.target) return;

    std::array<bool, max_target + 1> generated{};
    for (std::size_t left = 0; left < length; ++left) {
        for (std::size_t right = left; right < length; ++right) {
            const int candidate = state.chain[left] + state.chain[right];
            if (candidate <= last || candidate > state.target || generated[candidate]) continue;
            generated[candidate] = true;
            state.chain[length] = candidate;
            bool uses_last = false;
            for (std::size_t index = 0; index < length; ++index)
                uses_last = uses_last || last + state.chain[index] == candidate;
            visit(state, length + 1, prefix_is_brauer && uses_last);
        }
    }
}

int bit_length(int value) {
    int count = 0;
    while (value != 0) { ++count; value >>= 1; }
    return count;
}

int popcount(int value) {
    int count = 0;
    while (value != 0) { count += value & 1; value >>= 1; }
    return count;
}

std::array<std::int64_t, 3> minimum_counts(int target) {
    if (target == 1) return {0, 1, 0};
    const int lower = bit_length(target - 1);
    const int upper = bit_length(target) - 1 + popcount(target) - 1;
    for (int limit = lower; limit <= upper; ++limit) {
        Search state{target, limit};
        state.chain[0] = 1;
        visit(state, 1, true);
        if (state.total_count != 0)
            return {limit, state.brauer_count, state.total_count - state.brauer_count};
    }
    return {0, 0, 0};
}

void store_i64_le(std::uint8_t* output, std::size_t offset, std::int64_t value) noexcept {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>(bits >> (byte * 8));
}
}

extern "C" std::int64_t addition_chain_enumeration(const std::int64_t* input,
        std::size_t length, std::uint8_t* output, std::size_t capacity) noexcept {
    if (input == nullptr || length != 1 || input[0] < 1 || input[0] > max_target) return -1;
    const auto result = minimum_counts(static_cast<int>(input[0]));
    if (output == nullptr || capacity < output_bytes) return -2;
    for (std::size_t index = 0; index < result.size(); ++index)
        store_i64_le(output, index * 8, result[index]);
    return static_cast<std::int64_t>(output_bytes);
}
