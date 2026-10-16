#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MAX_OPS = 256;
constexpr std::uint64_t FNV_OFFSET = UINT64_C(14695981039346656037);
constexpr std::uint64_t FNV_PRIME = UINT64_C(1099511628211);
std::uint64_t hash_i64(std::uint64_t hash, std::int64_t value) {
    const auto bits = static_cast<std::uint64_t>(value);
    for (unsigned shift = 0; shift < 64; shift += 8) hash = (hash ^ static_cast<std::uint8_t>(bits >> shift)) * FNV_PRIME;
    return hash;
}
}

extern "C" std::int64_t immutable_hash_map(const std::int64_t *input, std::size_t length) {
    if (input == nullptr || length < 1 || length > 1 + 3 * MAX_OPS) return -1;
    const auto count64 = input[0];
    if (count64 < 0 || count64 > static_cast<std::int64_t>(MAX_OPS) || length != 1 + 3 * static_cast<std::size_t>(count64)) return -1;
    const auto count = static_cast<std::size_t>(count64);
    std::int32_t keys[MAX_OPS], values[MAX_OPS];
    std::int64_t trace[MAX_OPS];
    std::size_t map_size = 0;
    for (std::size_t i = 0; i < count; ++i) {
        const auto operation = input[1 + 3 * i];
        const auto key64 = input[2 + 3 * i];
        const auto value64 = input[3 + 3 * i];
        if (operation < 0 || operation > 3 || key64 < INT32_MIN || key64 > INT32_MAX || value64 < INT32_MIN || value64 > INT32_MAX) return -1;
        const auto key = static_cast<std::int32_t>(key64);
        const auto value = static_cast<std::int32_t>(value64);
        if (operation == 0) {
            if (value == 0) return -1;
            keys[map_size] = key; values[map_size] = value; ++map_size;
            trace[i] = static_cast<std::int64_t>(map_size);
        } else if (operation == 1 || operation == 2) {
            bool found = false;
            std::int32_t found_value = 0;
            for (std::size_t j = map_size; j > 0; --j) {
                if (keys[j - 1] == key) { found = true; found_value = values[j - 1]; break; }
            }
            trace[i] = operation == 1 ? found_value : static_cast<std::int64_t>(found);
        } else {
            trace[i] = static_cast<std::int64_t>(map_size);
        }
    }
    auto hash = hash_i64(FNV_OFFSET, static_cast<std::int64_t>(count));
    for (std::size_t i = 0; i < count; ++i) hash = hash_i64(hash, trace[i]);
    return static_cast<std::int64_t>(hash & UINT64_C(0x7fffffffffffffff));
}
