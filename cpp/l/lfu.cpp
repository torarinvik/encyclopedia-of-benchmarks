/* Source-faithful bounded trace of the pinned Go LFU cache. */
#include <array>
#include <cstddef>
#include <cstdint>
#include <climits>

namespace {
constexpr std::size_t kMinCapacity = 2;
constexpr std::size_t kMaxCapacity = 16;
constexpr std::size_t kMaxOperations = 32;
constexpr std::size_t kMaxInputLength = 2 + 3 * kMaxOperations;
constexpr std::size_t kMaxOutputWords = 3 * kMaxOperations;

void move_to_front(std::array<std::int32_t, kMaxCapacity>& keys,
                   std::array<std::int32_t, kMaxCapacity>& values,
                   std::size_t index) noexcept {
    const auto key = keys[index];
    const auto value = values[index];
    for (auto i = index; i > 0; --i) {
        keys[i] = keys[i - 1];
        values[i] = values[i - 1];
    }
    keys[0] = key;
    values[0] = value;
}

void append(std::array<std::int64_t, kMaxOutputWords>& words,
            std::size_t& count, std::int64_t value) noexcept {
    words[count++] = value;
}

void put_i64_le(std::uint8_t* output, std::size_t offset,
                std::int64_t value) noexcept {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
}

extern "C" std::int64_t lfu(const std::int64_t* input, std::size_t length,
                              std::uint8_t* output,
                              std::size_t output_capacity) noexcept {
    if (input == nullptr || length < 2 || length > kMaxInputLength) return -1;
    if (input[0] < static_cast<std::int64_t>(kMinCapacity) ||
        input[0] > static_cast<std::int64_t>(kMaxCapacity) ||
        input[1] < 0 || input[1] > static_cast<std::int64_t>(kMaxOperations)) return -1;

    const auto cache_capacity = static_cast<std::size_t>(input[0]);
    const auto operation_count = static_cast<std::size_t>(input[1]);
    std::array<std::int32_t, kMaxCapacity> keys{};
    std::array<std::int32_t, kMaxCapacity> values{};
    std::size_t size = 0;
    std::array<std::int64_t, kMaxOutputWords> words{};
    std::size_t word_count = 0;
    std::size_t position = 2;

    for (std::size_t operation = 0; operation < operation_count; ++operation) {
        if (position >= length) return -1;
        const auto opcode = input[position++];
        if (opcode == 0) {
            if (position + 1 >= length) return -1;
            const auto key_arg = input[position++];
            const auto value_arg = input[position++];
            if (key_arg < INT32_MIN || key_arg > INT32_MAX ||
                value_arg < INT32_MIN || value_arg > INT32_MAX) return -1;
            const auto key = static_cast<std::int32_t>(key_arg);
            std::size_t index = 0;
            while (index < size && keys[index] != key) ++index;
            if (index < size) {
                // The pinned Put mutates a copied item; the old value remains.
                move_to_front(keys, values, index);
            } else {
                if (size == cache_capacity) --size;
                for (std::size_t i = size; i > 0; --i) {
                    keys[i] = keys[i - 1];
                    values[i] = values[i - 1];
                }
                keys[0] = key;
                values[0] = static_cast<std::int32_t>(value_arg);
                ++size;
            }
            append(words, word_count, 0);
        } else if (opcode == 1) {
            if (position >= length) return -1;
            const auto key_arg = input[position++];
            if (key_arg < INT32_MIN || key_arg > INT32_MAX) return -1;
            const auto key = static_cast<std::int32_t>(key_arg);
            std::size_t index = 0;
            while (index < size && keys[index] != key) ++index;
            append(words, word_count, 1);
            if (index == size) {
                append(words, word_count, 1);
                append(words, word_count, 0);
            } else {
                const auto value = values[index];
                move_to_front(keys, values, index);
                append(words, word_count, 0);
                append(words, word_count, value);
            }
        } else {
            return -1;
        }
    }
    if (position != length || word_count > kMaxOutputWords) return -1;

    const auto output_length = word_count * 8;
    if (output == nullptr || output_capacity < output_length) return -2;
    for (std::size_t i = 0; i < word_count; ++i)
        put_i64_le(output, i * 8, words[i]);
    return static_cast<std::int64_t>(output_length);
}
