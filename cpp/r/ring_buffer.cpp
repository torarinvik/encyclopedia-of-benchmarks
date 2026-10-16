#include <cstddef>
#include <cstdint>

extern "C" std::int64_t ring_buffer(const std::int64_t *packed, std::size_t length) noexcept {
    constexpr std::int64_t ValueLimit = 1000000, ValueOffset = 1000001;
    constexpr std::int64_t HashMultiplier = 1000003, HashModulus = 1000000007;
    if (packed == nullptr || length < 1 || length > 513) return -1;
    const auto qv = packed[0];
    if (qv < 0 || qv > 256 || length != 1 + static_cast<std::size_t>(qv) * 2) return -1;
    const auto q = static_cast<std::size_t>(qv);
    for (std::size_t i = 0; i < q; ++i) {
        const auto op = packed[1 + i * 2], payload = packed[2 + i * 2];
        if (op == 0) { if (payload < -ValueLimit || payload > ValueLimit) return -1; }
        else if (op == 4) { if (payload < 0 || payload > ValueLimit) return -1; }
        else if (op >= 1 && op <= 3) { if (payload != 0) return -1; }
        else if (op >= 5 && op <= 9) { if (payload != 0) return -1; }
        else return -1;
    }

    std::int64_t values[8]{};
    std::size_t head = 0, tail = 0, count = 0;
    std::int64_t hash = 0;
    for (std::size_t i = 0; i < q; ++i) {
        const auto op = packed[1 + i * 2], payload = packed[2 + i * 2];
        std::int64_t status = 0, result = 0;
        if (op == 0) {
            if (count == 8) status = 1;
            else { values[tail] = payload; tail = (tail + 1) % 8; ++count; }
        } else if (op == 1) {
            if (count == 0) status = 2;
            else { result = values[head]; head = (head + 1) % 8; --count; }
        } else if (op == 2) {
            if (count == 0) status = 2;
            else result = values[head];
        } else if (op == 3) {
            if (count == 0) status = 2;
            else result = values[(tail + 7) % 8];
        } else if (op == 4) {
            if (payload >= static_cast<std::int64_t>(count)) status = 3;
            else result = values[(head + static_cast<std::size_t>(payload)) % 8];
        } else if (op == 5) {
            head = tail = count = 0;
        } else if (op == 6) result = static_cast<std::int64_t>(count);
        else if (op == 7) result = 8 - static_cast<std::int64_t>(count);
        else if (op == 8) result = count == 0;
        else result = count == 8;

        hash = (hash * HashMultiplier + op) % HashModulus;
        hash = (hash * HashMultiplier + status) % HashModulus;
        hash = (hash * HashMultiplier + result + ValueOffset) % HashModulus;
        hash = (hash * HashMultiplier + static_cast<std::int64_t>(count)) % HashModulus;
        for (std::size_t j = 0; j < count; ++j) {
            const auto position = (head + j) % 8;
            hash = (hash * HashMultiplier + values[position] + ValueOffset) % HashModulus;
        }
    }
    return hash;
}
