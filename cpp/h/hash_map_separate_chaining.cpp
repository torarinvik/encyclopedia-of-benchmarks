#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t MAX_OPERATIONS = 512;
constexpr std::size_t MAX_ENTRIES = 128;
constexpr std::int64_t MAX_KEY = 99999;
constexpr std::size_t BUCKET_COUNT = 16;
constexpr std::size_t MAX_INPUT_LENGTH = 1537;
constexpr std::uint64_t FNV_OFFSET = UINT64_C(0xcbf29ce484222325);
constexpr std::uint64_t FNV_PRIME = UINT64_C(0x100000001b3);
constexpr std::uint64_t RESULT_MASK = UINT64_C(0x7fffffffffffffff);

std::uint64_t hash_byte(std::uint64_t hash, std::uint8_t byte) {
    return (hash ^ byte) * FNV_PRIME;
}

std::uint64_t hash_i32(std::uint64_t hash, std::int64_t value) {
    const auto bits = static_cast<std::uint32_t>(value);
    for (unsigned shift = 0; shift < 32; shift += 8)
        hash = hash_byte(hash, static_cast<std::uint8_t>(bits >> shift));
    return hash;
}

int find_entry(const std::int64_t *keys, const int *next,
               const int *buckets, std::int64_t key) {
    for (int entry = buckets[static_cast<std::size_t>(key % static_cast<std::int64_t>(BUCKET_COUNT))];
         entry >= 0; entry = next[entry]) {
        if (keys[entry] == key) return entry;
    }
    return -1;
}
}

extern "C" std::int64_t hash_map_separate_chaining(const std::int64_t *input,
                                                     std::size_t length) {
    if (input == nullptr || length < 1 || length > MAX_INPUT_LENGTH) return -1;
    const std::int64_t operation_count = input[0];
    if (operation_count < 0 || operation_count > MAX_OPERATIONS ||
        length != 1 + 3 * static_cast<std::size_t>(operation_count)) return -1;

    std::int64_t keys[MAX_ENTRIES] = {}, mapped_values[MAX_ENTRIES] = {};
    int next[MAX_ENTRIES], buckets[BUCKET_COUNT], free_slots[MAX_ENTRIES];
    int free_count = static_cast<int>(MAX_ENTRIES), size = 0;
    for (std::size_t i = 0; i < MAX_ENTRIES; ++i) { next[i] = -1; free_slots[i] = static_cast<int>(i); }
    for (int &bucket : buckets) bucket = -1;
    std::uint64_t hash = FNV_OFFSET;

    for (std::int64_t operation = 0; operation < operation_count; ++operation) {
        const std::int64_t opcode = input[1 + 3 * static_cast<std::size_t>(operation)];
        const std::int64_t key = input[2 + 3 * static_cast<std::size_t>(operation)];
        const std::int64_t value = input[3 + 3 * static_cast<std::size_t>(operation)];
        std::uint8_t result_code = 0;
        std::int64_t returned_value = 0;

        if (opcode == 0) {
            if (key < 0 || key > MAX_KEY || value < INT32_MIN || value > INT32_MAX) return -1;
            const auto bucket = static_cast<std::size_t>(key % static_cast<std::int64_t>(BUCKET_COUNT));
            int entry = find_entry(keys, next, buckets, key);
            if (entry >= 0) mapped_values[entry] = value;
            else {
                if (size >= static_cast<int>(MAX_ENTRIES)) return -1;
                entry = free_slots[--free_count];
                keys[entry] = key; mapped_values[entry] = value;
                next[entry] = buckets[bucket]; buckets[bucket] = entry; ++size;
            }
        } else if (opcode == 1) {
            if (key < 0 || key > MAX_KEY || value != 0) return -1;
            const int entry = find_entry(keys, next, buckets, key);
            if (entry >= 0) { result_code = 1; returned_value = mapped_values[entry]; }
        } else if (opcode == 2) {
            if (key < 0 || key > MAX_KEY || value != 0) return -1;
            const auto bucket = static_cast<std::size_t>(key % static_cast<std::int64_t>(BUCKET_COUNT));
            int previous = -1, entry = buckets[bucket];
            while (entry >= 0) {
                const int following = next[entry];
                if (keys[entry] == key) {
                    if (previous < 0) buckets[bucket] = following;
                    else next[previous] = following;
                    free_slots[free_count++] = entry; --size; break;
                }
                previous = entry; entry = following;
            }
        } else if (opcode == 3) {
            if (key < 0 || key > MAX_KEY || value != 0) return -1;
            result_code = static_cast<std::uint8_t>(find_entry(keys, next, buckets, key) >= 0);
        } else if (opcode == 4) {
            if (key != 0 || value != 0) return -1;
            for (int &bucket : buckets) bucket = -1;
            for (std::size_t i = 0; i < MAX_ENTRIES; ++i) { next[i] = -1; free_slots[i] = static_cast<int>(i); }
            free_count = static_cast<int>(MAX_ENTRIES); size = 0;
        } else return -1;

        hash = hash_byte(hash, static_cast<std::uint8_t>(opcode));
        hash = hash_byte(hash, result_code);
        if (opcode == 1 && result_code == 1) hash = hash_i32(hash, returned_value);
    }
    return static_cast<std::int64_t>(hash & RESULT_MASK);
}
