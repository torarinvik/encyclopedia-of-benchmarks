/* Static ordered affine folds with a disjoint sparse table. */
#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t mod = 1'000'000'007;
constexpr std::size_t max_n = 32, max_q = 32, max_levels = 5;
struct Affine { std::int64_t a, b; };
Affine combine(Affine left, Affine right) noexcept {
    return {(right.a * left.a) % mod, (right.a * left.b + right.b) % mod};
}
void put_word(std::uint8_t *output, std::size_t offset, std::int64_t value) noexcept {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>(bits >> (byte * 8));
}
}

extern "C" std::int64_t disjoint_sparse_table_affine_composition(
    const std::int64_t *input, std::size_t length, std::uint8_t *output,
    std::size_t capacity) noexcept {
    if (input == nullptr || length < 2 || length > 130) return -1;
    const auto n_value = input[0], q_value = input[1];
    if (n_value < 1 || n_value > static_cast<std::int64_t>(max_n) ||
        q_value < 1 || q_value > static_cast<std::int64_t>(max_q)) return -1;
    const auto n = static_cast<std::size_t>(n_value), q = static_cast<std::size_t>(q_value);
    if (length != 2 + 2 * n + 2 * q) return -1;

    std::array<Affine, max_n> maps{};
    std::array<std::size_t, max_q> left{}, right{};
    std::size_t cursor = 2;
    for (std::size_t i = 0; i < n; ++i) {
        const auto a = input[cursor++], b = input[cursor++];
        if (a < 0 || a >= mod || b < 0 || b >= mod) return -1;
        maps[i] = {a, b};
    }
    for (std::size_t i = 0; i < q; ++i) {
        const auto lo = input[cursor++], hi = input[cursor++];
        if (lo < 0 || lo > hi || hi >= n_value) return -1;
        left[i] = static_cast<std::size_t>(lo);
        right[i] = static_cast<std::size_t>(hi);
    }
    const auto bytes = q * 16;
    if (output == nullptr || capacity < bytes) return -2;

    std::array<std::array<Affine, max_n>, max_levels> table{};
    std::size_t levels = 0;
    for (std::size_t span = 1; span < n; span <<= 1) ++levels;
    for (std::size_t level = 0; level < levels; ++level) {
        const std::size_t half = std::size_t{1} << level, width = half << 1;
        for (std::size_t start = 0; start < n; start += width) {
            const auto middle = (start + half < n) ? start + half : n;
            const auto end = (start + width < n) ? start + width : n;
            if (middle > start) {
                table[level][middle - 1] = maps[middle - 1];
                for (std::size_t i = middle - 1; i > start; --i)
                    table[level][i - 1] = combine(maps[i - 1], table[level][i]);
            }
            if (middle < end) {
                table[level][middle] = maps[middle];
                for (std::size_t i = middle + 1; i < end; ++i)
                    table[level][i] = combine(table[level][i - 1], maps[i]);
            }
        }
    }
    for (std::size_t query = 0; query < q; ++query) {
        Affine answer{};
        if (left[query] == right[query]) answer = maps[left[query]];
        else {
            auto difference = left[query] ^ right[query];
            std::size_t level = 0;
            while (difference > 1) { difference >>= 1; ++level; }
            answer = combine(table[level][left[query]], table[level][right[query]]);
        }
        put_word(output, query * 16, answer.a);
        put_word(output, query * 16 + 8, answer.b);
    }
    return static_cast<std::int64_t>(bytes);
}
