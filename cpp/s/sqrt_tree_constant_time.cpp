/* Clean-room power-of-two Sqrt Tree range-minimum profile. */
#include <algorithm>
#include <cstddef>
#include <cstdint>
#include <climits>
#include <iterator>

namespace {
constexpr std::size_t max_items = 64, max_queries = 64, max_levels = 4, max_input = 195;
constexpr std::int64_t value_limit = INT64_C(1000000000);

struct State {
    std::int64_t values[max_items]{};
    std::int64_t prefix[max_levels][max_items]{};
    std::int64_t suffix[max_levels][max_items]{};
    std::int64_t between[max_levels][max_items]{};
    std::size_t floor_log[max_items + 1]{};
    std::size_t padded_size{}, layer_count{};
    std::size_t segment_bits[max_levels]{}, block_bits[max_levels]{};
    int layer_for_diff[max_levels + 3]{};
};

void build(State& state, const std::int64_t* input, std::size_t n) {
    std::size_t padded = 1;
    while (padded < n) padded *= 2;
    state.padded_size = padded;
    for (std::size_t i = 0; i < n; ++i) state.values[i] = input[2 + i];
    for (std::size_t i = n; i < padded; ++i) state.values[i] = INT64_MAX;
    state.floor_log[0] = 0;
    state.floor_log[1] = 0;
    for (std::size_t i = 2; i <= padded; ++i) state.floor_log[i] = state.floor_log[i / 2] + 1;
    std::fill(std::begin(state.layer_for_diff), std::end(state.layer_for_diff), -1);
    std::size_t segment_bits = state.floor_log[padded];
    while (segment_bits > 1) {
        const auto level = state.layer_count++;
        const auto block_bits = (segment_bits + 1) / 2;
        state.segment_bits[level] = segment_bits;
        state.block_bits[level] = block_bits;
        for (std::size_t bit = block_bits; bit < segment_bits; ++bit) state.layer_for_diff[bit] = static_cast<int>(level);
        segment_bits = block_bits;
    }

    for (std::size_t level = 0; level < state.layer_count; ++level) {
        const auto seg_bits = state.segment_bits[level], blk_bits = state.block_bits[level];
        const std::size_t segment_size = std::size_t{1} << seg_bits;
        const std::size_t block_size = std::size_t{1} << blk_bits;
        const std::size_t block_count = segment_size / block_size;
        const std::size_t pair_count = block_count * block_count;
        for (std::size_t base = 0; base < padded; base += segment_size) {
            const std::size_t segment_index = base / segment_size;
            for (std::size_t block = 0; block < block_count; ++block) {
                const std::size_t start = base + block * block_size, end = start + block_size;
                state.prefix[level][start] = state.values[start];
                for (std::size_t i = start + 1; i < end; ++i)
                    state.prefix[level][i] = std::min(state.prefix[level][i - 1], state.values[i]);
                state.suffix[level][end - 1] = state.values[end - 1];
                for (std::size_t i = end - 1; i > start;) {
                    --i;
                    state.suffix[level][i] = std::min(state.values[i], state.suffix[level][i + 1]);
                }
            }
            for (std::size_t left = 0; left < block_count; ++left) {
                std::int64_t aggregate = INT64_MAX;
                for (std::size_t right = left; right < block_count; ++right) {
                    const std::size_t start = base + right * block_size;
                    aggregate = std::min(aggregate, state.suffix[level][start]);
                    const auto slot = segment_index * pair_count + left * block_count + right;
                    state.between[level][slot] = aggregate;
                }
            }
        }
    }
}

std::int64_t query(const State& state, std::size_t left, std::size_t right) {
    if (left == right) return state.values[left];
    const std::size_t difference = left ^ right;
    const std::size_t bit = state.floor_log[difference];
    if (bit == 0) return std::min(state.values[left], state.values[right]);
    const auto level = static_cast<std::size_t>(state.layer_for_diff[bit]);
    const auto segment_bits = state.segment_bits[level], block_bits = state.block_bits[level];
    const std::size_t segment_size = std::size_t{1} << segment_bits;
    const std::size_t block_size = std::size_t{1} << block_bits;
    const std::size_t base = (left / segment_size) * segment_size;
    const std::size_t segment_index = base / segment_size;
    const std::size_t block_count = segment_size / block_size;
    const std::size_t left_block = (left - base) / block_size;
    const std::size_t right_block = (right - base) / block_size;
    auto answer = std::min(state.suffix[level][left], state.prefix[level][right]);
    if (left_block + 1 < right_block) {
        const std::size_t pair_count = block_count * block_count;
        const auto slot = segment_index * pair_count + (left_block + 1) * block_count + right_block - 1;
        answer = std::min(answer, state.between[level][slot]);
    }
    return answer;
}

void store_i64_le(std::uint8_t* output, std::size_t offset, std::int64_t value) {
    auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) { output[offset + byte] = static_cast<std::uint8_t>(bits & 255); bits >>= 8; }
}
}

extern "C" std::int64_t sqrt_tree_constant_time(const std::int64_t* input, std::size_t length,
                                                  std::uint8_t* output, std::size_t output_capacity) noexcept {
    if (input == nullptr || length < 2 || length > max_input) return -1;
    const auto n_value = input[0], q_value = input[1];
    if (n_value < 1 || n_value > static_cast<std::int64_t>(max_items)
        || q_value < 0 || q_value > static_cast<std::int64_t>(max_queries)) return -1;
    const auto n = static_cast<std::size_t>(n_value), q = static_cast<std::size_t>(q_value);
    if (length != 2 + n + 2 * q) return -1;
    for (std::size_t i = 0; i < n; ++i)
        if (input[2 + i] < -value_limit || input[2 + i] > value_limit) return -1;
    const std::size_t query_offset = 2 + n;
    for (std::size_t i = 0; i < q; ++i) {
        const auto left = input[query_offset + 2 * i], right = input[query_offset + 2 * i + 1];
        if (left < 0 || right < left || right >= n_value) return -1;
    }
    const std::size_t required = 8 * q;
    if (output_capacity < required || (required != 0 && output == nullptr)) return -2;
    State state{};
    build(state, input, n);
    for (std::size_t i = 0; i < q; ++i) {
        const auto left = static_cast<std::size_t>(input[query_offset + 2 * i]);
        const auto right = static_cast<std::size_t>(input[query_offset + 2 * i + 1]);
        store_i64_le(output, 8 * i, query(state, left, right));
    }
    return static_cast<std::int64_t>(required);
}
