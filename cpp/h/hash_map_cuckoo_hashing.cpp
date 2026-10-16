#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_keys = 128;

std::int64_t positive_mod(std::int64_t value, std::int64_t divisor) {
    const auto result = value % divisor;
    return result < 0 ? result + divisor : result;
}

std::uint64_t fnv_word(std::uint64_t hash, std::int64_t word) {
    const auto bits = static_cast<std::uint64_t>(word);
    for (unsigned byte = 0; byte < 8; ++byte) {
        hash ^= (bits >> (byte * 8)) & UINT64_C(0xff);
        hash *= UINT64_C(1099511628211);
    }
    return hash;
}
}

extern "C" std::int64_t hash_map_cuckoo_hashing(
    const std::int64_t *input, std::size_t length) noexcept {
    if (input == nullptr || length < 2 || length > max_keys + 2) return -1;
    const auto capacity_value = input[0], count_value = input[1];
    if (capacity_value < 16 || capacity_value > 256 ||
        (capacity_value & (capacity_value - 1)) != 0 ||
        count_value < 0 || count_value > static_cast<std::int64_t>(max_keys) ||
        length != static_cast<std::size_t>(count_value) + 2) return -1;

    const auto capacity = capacity_value;
    const auto count = static_cast<std::size_t>(count_value);
    std::int64_t keys[max_keys]{};
    std::int64_t first_bucket[max_keys]{};
    std::int64_t second_bucket[max_keys]{};
    for (std::size_t i = 0; i < count; ++i) {
        const auto key = input[2 + i];
        if (key < INT32_MIN || key > INT32_MAX || key == INT32_MIN) return -1;
        keys[i] = key;
        first_bucket[i] = positive_mod(key, capacity);
        second_bucket[i] = positive_mod(key / capacity, capacity);
        for (std::size_t j = 0; j < i; ++j) if (keys[j] == key) return -1;
    }

    const bool class_a = count == 2 && first_bucket[0] == first_bucket[1] &&
                         second_bucket[0] != first_bucket[0];
    bool class_b = true;
    for (std::size_t i = 0; i < count; ++i)
        for (std::size_t j = 0; j < i; ++j)
            if (first_bucket[i] == first_bucket[j]) class_b = false;
    if (!class_a && !class_b) return -1;

    std::int64_t slots[max_keys * 2];
    bool occupied[max_keys * 2]{};
    for (auto &slot : slots) slot = -1;
    auto final_capacity = capacity;
    if (class_b) {
        std::size_t size = 0;
        for (std::size_t i = 0; i < count; ++i) {
            slots[first_bucket[i]] = keys[i];
            occupied[first_bucket[i]] = true;
            ++size;
            if (static_cast<double>(size) / static_cast<double>(final_capacity) > 0.7)
                final_capacity *= 2;
        }
        for (std::size_t bucket = 0; bucket < max_keys * 2; ++bucket) {
            slots[bucket] = -1;
            occupied[bucket] = false;
        }
        for (std::size_t i = 0; i < count; ++i) {
            const auto bucket = positive_mod(keys[i], final_capacity);
            slots[bucket] = keys[i];
            occupied[bucket] = true;
        }
    } else {
        slots[second_bucket[0]] = keys[0];
        occupied[second_bucket[0]] = true;
        slots[first_bucket[1]] = keys[1];
        occupied[first_bucket[1]] = true;
    }

    auto hash = UINT64_C(14695981039346656037);
    hash = fnv_word(hash, static_cast<std::int64_t>(count));
    for (std::size_t i = 0; i < count; ++i) {
        std::int64_t found = -1;
        for (std::int64_t bucket = 0; bucket < final_capacity; ++bucket)
            if (occupied[bucket] && slots[bucket] == keys[i]) { found = bucket; break; }
        if (found < 0) return -1;
        hash = fnv_word(hash, found);
    }
    return static_cast<std::int64_t>(hash & UINT64_C(0x7fffffffffffffff));
}
