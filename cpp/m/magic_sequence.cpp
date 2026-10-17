#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MAX_N = 11;
constexpr std::uint64_t FNV_OFFSET_BASIS = UINT64_C(14695981039346656037);
constexpr std::uint64_t FNV_PRIME = UINT64_C(1099511628211);
constexpr std::uint64_t I64_RESULT_MASK = UINT64_C(0x7fffffffffffffff);

void fnv_byte(std::uint64_t &hash, std::uint8_t value)
{
    hash = (hash ^ static_cast<std::uint64_t>(value)) * FNV_PRIME;
}

std::uint32_t enumerate(std::uint8_t n, std::uint64_t &hash, bool hash_rows)
{
    if (n == 0) return 1;

    std::array<std::uint8_t, MAX_N> vector{};
    std::array<std::uint8_t, MAX_N> frequencies{};
    std::array<std::uint8_t, MAX_N> next_candidate{};
    std::array<std::uint8_t, MAX_N + 1> prefix_sum{};
    std::size_t depth = 0;
    std::uint32_t solution_count = 0;

    for (;;) {
        if (depth == n) {
            bool is_magic = true;
            for (std::size_t symbol = 0; symbol < n; ++symbol) {
                if (frequencies[symbol] != vector[symbol]) {
                    is_magic = false;
                    break;
                }
            }
            if (is_magic) {
                ++solution_count;
                if (hash_rows) {
                    for (std::size_t index = 0; index < n; ++index) {
                        fnv_byte(hash, vector[index]);
                    }
                }
            }
            --depth;
            --frequencies[vector[depth]];
            continue;
        }

        const std::uint8_t candidate = next_candidate[depth];
        if (candidate >= n) {
            next_candidate[depth] = 0;
            if (depth == 0) break;
            --depth;
            --frequencies[vector[depth]];
            continue;
        }
        next_candidate[depth] = static_cast<std::uint8_t>(candidate + 1);
        const std::uint8_t sum = static_cast<std::uint8_t>(prefix_sum[depth] + candidate);
        if (sum > n) continue;

        vector[depth] = candidate;
        ++frequencies[candidate];
        prefix_sum[depth + 1] = sum;
        ++depth;
        next_candidate[depth] = 0;
    }
    return solution_count;
}
}  // namespace

extern "C" std::int64_t magic_sequence(const std::int64_t *input, std::size_t length)
{
    if (input == nullptr || length != 1 || input[0] < 0 || input[0] > MAX_N) return -1;
    const auto n = static_cast<std::uint8_t>(input[0]);

    std::uint64_t hash = FNV_OFFSET_BASIS;
    fnv_byte(hash, n);
    const std::uint32_t solution_count = enumerate(n, hash, false);
    for (unsigned int shift = 0; shift < 32; shift += 8) {
        fnv_byte(hash, static_cast<std::uint8_t>(solution_count >> shift));
    }
    (void)enumerate(n, hash, true);
    return static_cast<std::int64_t>(hash & I64_RESULT_MASK);
}
