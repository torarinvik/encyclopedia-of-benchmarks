#include <algorithm>
#include <cstddef>
#include <cstdint>

namespace {
constexpr int max_n = 64;
constexpr int max_q = 64;
constexpr int max_value = 255;
constexpr std::size_t max_parseable_input_words = 2 + max_n + 2 * max_q + 1;
constexpr std::size_t max_output_bytes = 4 * max_q;

struct Query { int left, right, index; };

void put_i32_le(std::uint8_t* output, std::size_t offset, std::int32_t value) {
    const auto bits = static_cast<std::uint32_t>(value);
    for (std::size_t byte = 0; byte < 4; ++byte) output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}

int ceil_sqrt(int n) {
    int block = 1;
    while (block * block < n) ++block;
    return block;
}
}

extern "C" std::int64_t mo(const std::int32_t* input, std::size_t length,
    std::uint8_t* output, std::size_t capacity) {
    if (input == nullptr || length < 2 || length > max_parseable_input_words) return -1;
    const auto n_raw = input[0];
    if (n_raw < 1 || n_raw > max_n) return -1;
    const int n = static_cast<int>(n_raw);
    const std::size_t q_offset = 1 + static_cast<std::size_t>(n);
    if (length <= q_offset) return -1;
    const auto q_raw = input[q_offset];
    if (q_raw < 0 || q_raw > max_q || length != q_offset + 1 + 2 * static_cast<std::size_t>(q_raw)) return -1;
    const int q_count = static_cast<int>(q_raw);
    for (int i = 0; i < n; ++i) if (input[1 + i] < 0 || input[1 + i] > max_value) return -1;

    Query queries[max_q];
    for (int i = 0; i < q_count; ++i) {
        const auto left = input[q_offset + 1 + 2 * static_cast<std::size_t>(i)];
        const auto right = input[q_offset + 2 + 2 * static_cast<std::size_t>(i)];
        if (left < 1 || right < left || right > n) return -1;
        queries[i] = {static_cast<int>(left - 1), static_cast<int>(right - 1), i};
    }
    const std::size_t bytes = 4 * static_cast<std::size_t>(q_count);
    if (output == nullptr || capacity < bytes) return -2;

    const int block_size = ceil_sqrt(n);
    std::sort(queries, queries + q_count, [block_size](const Query& a, const Query& b) {
        const int a_block = a.left / block_size;
        const int b_block = b.left / block_size;
        if (a_block != b_block) return a_block < b_block;
        return a.right < b.right;
    });

    int frequencies[max_value + 1]{};
    int answers[max_q]{};
    int distinct = 0, left = 0, right = 0;
    for (int i = 0; i < q_count; ++i) {
        const int target_left = queries[i].left;
        const int target_right = queries[i].right;
        while (left < target_left) {
            const int value = input[1 + left++];
            if (--frequencies[value] == 0) --distinct;
        }
        while (left > target_left) {
            const int value = input[1 + --left];
            if (++frequencies[value] == 1) ++distinct;
        }
        while (right <= target_right) {
            const int value = input[1 + right++];
            if (++frequencies[value] == 1) ++distinct;
        }
        while (right > target_right + 1) {
            const int value = input[1 + --right];
            if (--frequencies[value] == 0) --distinct;
        }
        answers[queries[i].index] = distinct;
    }

    for (int i = 0; i < q_count; ++i) put_i32_le(output, 4 * static_cast<std::size_t>(i), answers[i]);
    return static_cast<std::int64_t>(bytes);
}
