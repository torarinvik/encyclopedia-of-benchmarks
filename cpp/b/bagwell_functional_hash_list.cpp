/* Clean-room bounded Bagwell functional hash-list. */
#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::array<int, 3> starts{0, 8, 24};
constexpr std::array<int, 3> sides{8, 16, 32};
void put_i64_le(std::uint8_t *out, std::size_t at, std::int64_t value) {
    const auto bits = static_cast<std::uint64_t>(value);
    for (unsigned b = 0; b < 8; ++b) out[at + b] = static_cast<std::uint8_t>(bits >> (8 * b));
}
}

extern "C" std::int64_t bagwell_functional_hash_list(
    const std::int64_t *input, std::size_t length, std::uint8_t *output, std::size_t capacity) {
    if (input == nullptr || length < 2 || length > 131) return -1;
    const auto nv = input[0];
    if (nv < 0 || nv > 32) return -1;
    const auto n = static_cast<std::size_t>(nv), q_at = 1 + 2 * n;
    if (q_at >= length) return -1;
    const auto qv = input[q_at];
    if (qv < 1 || qv > 32) return -1;
    const auto q = static_cast<std::size_t>(qv), query_at = q_at + 1;
    if (length != 2 + 2 * n + 2 * q) return -1;
    for (std::size_t i = 0; i < n; ++i)
        if (input[1 + 2 * i] < INT32_MIN || input[1 + 2 * i] > INT32_MAX
            || input[2 + 2 * i] < INT32_MIN || input[2 + 2 * i] > INT32_MAX) return -1;
    for (std::size_t j = 0; j < q; ++j) {
        const auto root = input[query_at + 2 * j], key = input[query_at + 2 * j + 1];
        if (root < 0 || root > nv || key < INT32_MIN || key > INT32_MAX) return -1;
    }
    const auto bytes = 8 * q;
    if (output == nullptr || capacity < bytes) return -2;

    std::array<std::int64_t, 56> keys{}, values{};
    std::array<int, 56> next{}, heads{};
    std::array<int, 3> prev{};
    std::array<int, 33> root_block{}, root_offset{};
    next.fill(-1); heads.fill(-1); prev.fill(-1); root_block.fill(-1); root_offset.fill(-1);
    int current = 0;
    for (int i = 0; i < static_cast<int>(n); ++i) {
        if (i == 8 || i == 24) { prev[static_cast<std::size_t>(current + 1)] = current; ++current; }
        const int offset = i - starts[static_cast<std::size_t>(current)];
        const int slot = starts[static_cast<std::size_t>(current)] + offset;
        const auto hash = static_cast<std::uint32_t>(input[1 + 2 * static_cast<std::size_t>(i)]);
        const int bucket = static_cast<int>(hash & static_cast<std::uint32_t>(sides[static_cast<std::size_t>(current)] - 1));
        const int head_slot = starts[static_cast<std::size_t>(current)] + bucket;
        keys[static_cast<std::size_t>(slot)] = input[1 + 2 * static_cast<std::size_t>(i)];
        values[static_cast<std::size_t>(slot)] = input[2 + 2 * static_cast<std::size_t>(i)];
        next[static_cast<std::size_t>(slot)] = heads[static_cast<std::size_t>(head_slot)];
        heads[static_cast<std::size_t>(head_slot)] = offset;
        root_block[static_cast<std::size_t>(i + 1)] = current;
        root_offset[static_cast<std::size_t>(i + 1)] = offset;
    }
    for (std::size_t j = 0; j < q; ++j) {
        const auto root = static_cast<std::size_t>(input[query_at + 2 * j]);
        const auto key = input[query_at + 2 * j + 1];
        int block = root_block[root], limit = root_offset[root];
        std::int64_t answer = INT64_MIN;
        if (block >= 0) {
            const auto hash = static_cast<std::uint32_t>(key);
            bool first = true;
            while (block >= 0 && answer == INT64_MIN) {
                const auto b = static_cast<std::size_t>(block);
                const int bucket = static_cast<int>(hash & static_cast<std::uint32_t>(sides[b] - 1));
                int chain = heads[static_cast<std::size_t>(starts[b] + bucket)];
                while (chain >= 0) {
                    const auto slot = static_cast<std::size_t>(starts[b] + chain);
                    if ((!first || chain <= limit) && keys[slot] == key) { answer = values[slot]; break; }
                    chain = next[slot];
                }
                block = prev[b]; first = false;
            }
        }
        put_i64_le(output, 8 * j, answer);
    }
    return static_cast<std::int64_t>(bytes);
}
