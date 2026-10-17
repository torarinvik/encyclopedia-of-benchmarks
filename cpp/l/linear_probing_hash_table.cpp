#include <cstddef>
#include <cstdint>
#include <climits>

namespace {
constexpr std::size_t kMaxInitialCapacity = 16;
constexpr std::size_t kMaxTableCapacity = 128;
constexpr std::size_t kMaxOperations = 32;
constexpr std::size_t kMaxInputLength = 66;
constexpr std::size_t kMaxOutputWords = 1088;
constexpr std::int64_t kMaxKey = INT32_MAX - 127;

std::int32_t find_slot(const std::int32_t* table, std::size_t capacity, std::int32_t key) {
    auto index = static_cast<std::size_t>(key) % capacity;
    for (std::size_t probes = 0; probes < capacity; ++probes) {
        if (table[index] == 0) return -1;
        if (table[index] == key) return static_cast<std::int32_t>(index);
        index = (index + 1) % capacity;
    }
    return -1;
}

std::int32_t insertion_slot(const std::int32_t* table, std::size_t capacity, std::int32_t key) {
    auto index = static_cast<std::size_t>(key) % capacity;
    for (std::size_t probes = 0; probes < capacity; ++probes) {
        if (table[index] == 0 || table[index] == -1) return static_cast<std::int32_t>(index);
        index = (index + 1) % capacity;
    }
    return -1;
}

void rehash(std::int32_t* table, std::size_t& capacity) {
    std::int32_t old_table[kMaxTableCapacity];
    const auto old_capacity = capacity;
    for (std::size_t i = 0; i < old_capacity; ++i) old_table[i] = table[i];
    capacity *= 2;
    for (std::size_t i = 0; i < capacity; ++i) table[i] = 0;
    for (std::size_t i = 0; i < old_capacity; ++i) {
        const auto key = old_table[i];
        if (key <= 0) continue;
        const auto slot = insertion_slot(table, capacity, key);
        if (slot >= 0) table[slot] = key;
    }
}
}

extern "C" std::int64_t linear_probing_hash_table(const std::int64_t* input, std::size_t length,
                                                    std::uint8_t* output, std::size_t output_capacity) {
    if (input == nullptr || length < 2 || length > kMaxInputLength) return -1;
    if (input[0] < 2 || input[0] > static_cast<std::int64_t>(kMaxInitialCapacity) ||
        input[1] < 0 || input[1] > static_cast<std::int64_t>(kMaxOperations)) return -1;
    std::size_t table_capacity = static_cast<std::size_t>(input[0]);
    const auto operation_count = static_cast<std::size_t>(input[1]);
    std::int32_t table[kMaxTableCapacity]{};
    std::size_t size = 0, position = 2, word_count = 0;
    std::int64_t words[kMaxOutputWords];

    for (std::size_t operation = 0; operation < operation_count; ++operation) {
        if (position >= length) return -1;
        const auto opcode = input[position++];
        if (opcode >= 0 && opcode <= 3) {
            if (position >= length) return -1;
            const auto key_arg = input[position++];
            if (key_arg < 1 || key_arg > kMaxKey) return -1;
            const auto key = static_cast<std::int32_t>(key_arg);
            if (opcode == 0) {
                const auto slot = insertion_slot(table, table_capacity, key);
                if (slot < 0) return -1;
                table[slot] = key;
                ++size;
                words[word_count++] = 0; words[word_count++] = 1;
                if (size * 2 >= table_capacity) rehash(table, table_capacity);
            } else if (opcode == 1) {
                const auto slot = find_slot(table, table_capacity, key);
                if (slot < 0) return -1;
                table[slot] = -1;
                --size;
                words[word_count++] = 1; words[word_count++] = 1;
            } else if (opcode == 2) {
                words[word_count++] = 2;
                words[word_count++] = find_slot(table, table_capacity, key) >= 0 ? 1 : 0;
            } else {
                words[word_count++] = 3; words[word_count++] = key;
            }
        } else if (opcode == 4) {
            words[word_count++] = 4; words[word_count++] = static_cast<std::int64_t>(table_capacity);
            for (std::size_t i = 0; i < table_capacity; ++i)
                words[word_count++] = table[i] == 0 ? -2 : table[i];
        } else return -1;
    }
    if (position != length || word_count > kMaxOutputWords) return -1;
    const auto output_length = word_count * 8;
    if (output == nullptr || output_capacity < output_length) return -2;
    for (std::size_t i = 0; i < word_count; ++i) {
        const auto bits = static_cast<std::uint64_t>(words[i]);
        for (std::size_t byte = 0; byte < 8; ++byte)
            output[8 * i + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
    }
    return static_cast<std::int64_t>(output_length);
}
