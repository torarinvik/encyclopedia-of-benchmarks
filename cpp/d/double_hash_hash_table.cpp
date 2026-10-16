#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t op_limit = 512, cap_limit = 101;
enum : int { empty = 0, occupied = 1, tombstone = 2 };
bool prime(std::int64_t n) {
    if (n < 2) return false;
    for (std::int64_t d = 2; d * d <= n; ++d) if (n % d == 0) return false;
    return true;
}
}

extern "C" std::int64_t double_hash_hash_table(const std::int64_t *input, std::size_t length) {
    if (!input || length < 2) return -1;
    const auto cap64 = input[0], count64 = input[1];
    if (cap64 < 3 || cap64 > static_cast<std::int64_t>(cap_limit) || !prime(cap64) || count64 < 0 || count64 > static_cast<std::int64_t>(op_limit) || length != 2 + 2 * static_cast<std::size_t>(count64)) return -1;
    const auto cap = static_cast<std::size_t>(cap64);
    std::array<int, cap_limit> state{};
    std::array<std::int64_t, cap_limit> keys{};
    std::int64_t successes = 0;
    for (std::size_t i = 0; i < static_cast<std::size_t>(count64); ++i) {
        const auto op = input[2 + 2 * i], key = input[3 + 2 * i];
        if (op < 1 || op > 3) return -1;
        const auto first = static_cast<std::size_t>((key % cap64 + cap64) % cap64);
        const auto step = 1 + static_cast<std::size_t>((key % (cap64 - 1) + cap64 - 1) % (cap64 - 1));
        if (op == 1) {
            std::size_t tomb = cap;
            bool inserted = false;
            for (std::size_t p = 0; p < cap; ++p) {
                const auto slot = (first + p * step) % cap;
                if (state[slot] == occupied && keys[slot] == key) { tomb = cap; break; }
                if (state[slot] == tombstone && tomb == cap) tomb = slot;
                if (state[slot] == empty) { const auto target = tomb == cap ? slot : tomb; state[target] = occupied; keys[target] = key; inserted = true; break; }
            }
            if (!inserted && tomb != cap) { state[tomb] = occupied; keys[tomb] = key; inserted = true; }
            successes += inserted;
        } else {
            for (std::size_t p = 0; p < cap; ++p) {
                const auto slot = (first + p * step) % cap;
                if (state[slot] == empty) break;
                if (state[slot] == occupied && keys[slot] == key) { ++successes; if (op == 3) state[slot] = tombstone; break; }
            }
        }
    }
    return successes;
}
