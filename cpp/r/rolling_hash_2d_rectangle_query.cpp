#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_height = 32, max_width = 32, max_queries = 128;
constexpr std::size_t max_input_length = 1540, max_output_bytes = 1024;
constexpr std::int64_t modulus = 1'000'000'007, row_base = 31, column_base = 37;

void store_i64_le(std::uint8_t *output, std::size_t offset, std::int64_t value) {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
}

extern "C" std::int64_t rolling_hash_2d_rectangle_query(
    const std::int64_t *input, std::size_t length, std::uint8_t *output,
    std::size_t capacity) {
    if (input == nullptr || length < 3 || length > max_input_length) return -1;
    const auto h_value = input[0], w_value = input[1], q_value = input[2];
    if (h_value < 1 || h_value > static_cast<std::int64_t>(max_height) ||
        w_value < 1 || w_value > static_cast<std::int64_t>(max_width) ||
        q_value < 1 || q_value > static_cast<std::int64_t>(max_queries)) return -1;
    const auto h = static_cast<std::size_t>(h_value);
    const auto w = static_cast<std::size_t>(w_value);
    const auto q = static_cast<std::size_t>(q_value);
    if (length != 3 + h * w + 4 * q) return -1;
    const std::size_t query_offset = 3 + h * w;
    for (std::size_t i = 0; i < h * w; ++i)
        if (input[3 + i] < 0 || input[3 + i] > 255) return -1;
    for (std::size_t i = 0; i < q; ++i) {
        const auto r0 = input[query_offset + 4 * i];
        const auto c0 = input[query_offset + 4 * i + 1];
        const auto r1 = input[query_offset + 4 * i + 2];
        const auto c1 = input[query_offset + 4 * i + 3];
        if (r0 < 0 || r0 > r1 || r1 > h_value || c0 < 0 || c0 > c1 || c1 > w_value) return -1;
    }
    const std::size_t required = 8 * q;
    if (output == nullptr || capacity < required) return -2;

    std::array<std::int64_t, max_height + 1> row_power{};
    std::array<std::int64_t, max_width + 1> col_power{};
    row_power[0] = col_power[0] = 1;
    for (std::size_t i = 1; i <= h; ++i) row_power[i] = row_power[i - 1] * row_base % modulus;
    for (std::size_t j = 1; j <= w; ++j) col_power[j] = col_power[j - 1] * column_base % modulus;
    std::array<std::array<std::int64_t, max_width + 1>, max_height + 1> prefix{};
    for (std::size_t r = 1; r <= h; ++r) {
        std::int64_t row_hash = 0;
        for (std::size_t c = 1; c <= w; ++c) {
            row_hash = (row_hash * column_base + input[3 + (r - 1) * w + c - 1]) % modulus;
            prefix[r][c] = (prefix[r - 1][c] * row_base + row_hash) % modulus;
        }
    }
    std::array<std::uint8_t, max_output_bytes> staged{};
    for (std::size_t i = 0; i < q; ++i) {
        const auto r0 = static_cast<std::size_t>(input[query_offset + 4 * i]);
        const auto c0 = static_cast<std::size_t>(input[query_offset + 4 * i + 1]);
        const auto r1 = static_cast<std::size_t>(input[query_offset + 4 * i + 2]);
        const auto c1 = static_cast<std::size_t>(input[query_offset + 4 * i + 3]);
        const auto rh = r1 - r0, cw = c1 - c0;
        auto value = prefix[r1][c1]
            - prefix[r0][c1] * row_power[rh] % modulus
            - prefix[r1][c0] * col_power[cw] % modulus
            + prefix[r0][c0] * row_power[rh] % modulus * col_power[cw] % modulus;
        value %= modulus;
        if (value < 0) value += modulus;
        store_i64_le(staged.data(), 8 * i, value);
    }
    for (std::size_t i = 0; i < required; ++i) output[i] = staged[i];
    return static_cast<std::int64_t>(required);
}
