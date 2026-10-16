#include <cstddef>
#include <cstdint>

extern "C" std::int64_t queue_using_array2(const std::int64_t *packed, std::size_t length) noexcept {
    constexpr std::int64_t ValueLimit = 1000000, ValueOffset = 1000001;
    constexpr std::int64_t HashMultiplier = 1000003, HashModulus = 1000000007;
    if (packed == nullptr || length < 1 || length > 513) return -1;
    const auto qv = packed[0];
    if (qv < 0 || qv > 256 || length != 1 + static_cast<std::size_t>(qv) * 2) return -1;
    const auto q = static_cast<std::size_t>(qv);
    for (std::size_t i = 0; i < q; ++i) {
        const auto op = packed[1 + i * 2], value = packed[2 + i * 2];
        if (op == 1) { if (value < -ValueLimit || value > ValueLimit) return -1; }
        else if (op == 2 || op == 3) { if (value != 0) return -1; }
        else return -1;
    }

    std::int64_t values[10]{};
    std::size_t count = 0;
    std::int64_t hash = 0;
    for (std::size_t i = 0; i < q; ++i) {
        const auto op = packed[1 + i * 2], value = packed[2 + i * 2];
        if (op == 1) {
            if (count < 10) values[count++] = value;
        } else if (op == 2 && count > 0) {
            for (std::size_t j = 1; j < count; ++j) values[j - 1] = values[j];
            --count;
        }

        hash = (hash * HashMultiplier + op) % HashModulus;
        hash = (hash * HashMultiplier + static_cast<std::int64_t>(count)) % HashModulus;
        for (std::size_t j = 0; j < count; ++j)
            hash = (hash * HashMultiplier + values[j] + ValueOffset) % HashModulus;
    }
    return hash;
}
