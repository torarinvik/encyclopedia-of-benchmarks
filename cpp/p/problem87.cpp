#include <cstdint>
#include <vector>

static std::int64_t integer_sqrt(std::int64_t value) { std::int64_t root = 0; while ((root + 1) * (root + 1) <= value) ++root; return root; }
extern "C" std::int64_t problem87(std::int64_t limit) noexcept {
    if (limit < 24 || limit > 50'000'000) return -1;
    const auto root = integer_sqrt(limit - 24);
    const std::int64_t bound = root < 2 ? 2 : root;
    std::vector<std::uint8_t> prime(static_cast<std::size_t>(bound) + 1, 1);
    prime[0] = prime[1] = 0;
    for (std::int64_t p = 2; p * p <= bound; ++p) if (prime[p])
        for (std::int64_t multiple = p * p; multiple <= bound; multiple += p) prime[multiple] = 0;
    const std::size_t bytes = static_cast<std::size_t>((limit + 7) / 8);
    std::vector<std::uint8_t> seen(bytes, 0);
    for (std::int64_t p1 = 2; p1 <= bound; ++p1) if (prime[p1]) {
        const auto square = p1 * p1;
        for (std::int64_t p2 = 2; p2 <= bound; ++p2) if (prime[p2]) {
            const auto cube = p2 * p2 * p2;
            if (square + cube >= limit - 16) break;
            for (std::int64_t p3 = 2; p3 <= bound; ++p3) if (prime[p3]) {
                const auto total = square + cube + p3 * p3 * p3 * p3;
                if (total >= limit) break;
                seen[static_cast<std::size_t>(total) >> 3] |= static_cast<std::uint8_t>(1u << (total & 7));
            }
        }
    }
    std::int64_t count = 0;
    for (auto bits : seen) for (; bits != 0; bits &= static_cast<std::uint8_t>(bits - 1)) ++count;
    return count;
}
