#include <cstddef>
#include <cstdint>

extern "C" std::int64_t two_pset(const std::int64_t *packed, std::size_t length) noexcept {
    constexpr std::int64_t HashMultiplier = 1000003, HashModulus = 1000000007;
    if (packed == nullptr || length < 1 || length > 1025) return -1;
    const auto qv = packed[0];
    if (qv < 0 || qv > 256 || length != 1 + static_cast<std::size_t>(qv) * 4) return -1;
    const auto q = static_cast<std::size_t>(qv);
    for (std::size_t i = 0; i < q; ++i) {
        const auto op = packed[1 + i * 4], set_id = packed[2 + i * 4];
        const auto value = packed[3 + i * 4], other_id = packed[4 + i * 4];
        if (op >= 0 && op <= 2) {
            if (set_id < 0 || set_id > 1 || value < 0 || value > 63 || other_id != 0) return -1;
        } else if (op == 3 || op == 4) {
            if (set_id < 0 || set_id > 1 || value != 0 || other_id < 0 || other_id > 1) return -1;
        } else return -1;
    }

    std::int64_t additions[128]{}, tombstones[128]{};
    std::int64_t digest = 0;
    for (std::size_t i = 0; i < q; ++i) {
        const auto op = packed[1 + i * 4], set_id = packed[2 + i * 4];
        const auto value = packed[3 + i * 4], other_id = packed[4 + i * 4];
        const auto base = static_cast<std::size_t>(set_id) * 64;
        std::int64_t result = 0;
        if (op == 0) additions[base + static_cast<std::size_t>(value)] = 1;
        else if (op == 1) {
            const auto index = base + static_cast<std::size_t>(value);
            if (additions[index] != 0 && tombstones[index] == 0) tombstones[index] = 1;
        } else if (op == 2) {
            const auto index = base + static_cast<std::size_t>(value);
            result = additions[index] != 0 && tombstones[index] == 0;
        } else if (op == 3) {
            const auto other_base = static_cast<std::size_t>(other_id) * 64;
            result = 1;
            for (std::size_t e = 0; e < 64; ++e) {
                if ((additions[base + e] != 0 && additions[other_base + e] == 0) ||
                    (tombstones[base + e] != 0 && tombstones[other_base + e] == 0)) result = 0;
            }
        } else {
            const auto other_base = static_cast<std::size_t>(other_id) * 64;
            for (std::size_t e = 0; e < 64; ++e) {
                additions[base + e] = additions[base + e] || additions[other_base + e];
                tombstones[base + e] = tombstones[base + e] || tombstones[other_base + e];
            }
        }
        digest = (digest * HashMultiplier + op) % HashModulus;
        digest = (digest * HashMultiplier + result) % HashModulus;
    }

    for (std::size_t set_id = 0; set_id < 2; ++set_id) {
        const auto base = set_id * 64;
        for (std::size_t e = 0; e < 64; ++e) digest = (digest * HashMultiplier + additions[base + e]) % HashModulus;
        for (std::size_t e = 0; e < 64; ++e) digest = (digest * HashMultiplier + tombstones[base + e]) % HashModulus;
    }
    return digest;
}
