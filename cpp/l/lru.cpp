#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_input_length = 99;
constexpr std::size_t max_operations = 32;
constexpr std::size_t max_capacity = 16;
constexpr std::size_t max_output_fields = 114;

void append(std::int64_t *records, std::size_t &count, std::int64_t value)
{
    records[count++] = value;
}

void write_i64_le(std::uint8_t *output, std::size_t offset, std::int64_t value)
{
    auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = static_cast<std::uint8_t>(bits);
        bits >>= 8;
    }
}
} // namespace

extern "C" std::int64_t lru(const std::int64_t *input, std::size_t length,
                            std::uint8_t *output, std::size_t output_capacity)
{
    if (input == nullptr || length < 2 || length > max_input_length) return -1;
    const auto capacity_value = input[0];
    const auto operation_count = input[1];
    if (capacity_value < 2 || capacity_value > static_cast<std::int64_t>(max_capacity)
        || operation_count < 0 || operation_count > static_cast<std::int64_t>(max_operations)
        || length != 2 + 3 * static_cast<std::size_t>(operation_count)) return -1;
    const auto capacity = static_cast<std::size_t>(capacity_value);

    std::int64_t keys[max_capacity], values[max_capacity], seen[max_operations];
    std::size_t order[max_capacity];
    std::int64_t records[max_output_fields];
    std::size_t cache_count = 0, seen_count = 0, record_count = 0, cursor = 2;
    for (std::int64_t step = 0; step < operation_count; ++step) {
        const auto opcode = input[cursor++];
        const auto key = input[cursor++];
        const auto value = input[cursor++];
        if (key < -1'000'000 || key > 1'000'000) return -1;
        if (opcode == 0) {
            if (value < -1'000'000 || value > 1'000'000) return -1;
            for (std::size_t index = 0; index < seen_count; ++index)
                if (seen[index] == key) return -1;
            seen[seen_count++] = key;
            std::size_t slot;
            if (cache_count == capacity) {
                slot = order[0];
                for (std::size_t index = 0; index + 1 < cache_count; ++index)
                    order[index] = order[index + 1];
                --cache_count;
            } else {
                slot = cache_count;
            }
            keys[slot] = key;
            values[slot] = value;
            order[cache_count++] = slot;
            append(records, record_count, 0);
            append(records, record_count, 0);
        } else if (opcode == 1) {
            if (value != 0) return -1;
            std::size_t position = 0;
            while (position < cache_count && keys[order[position]] != key) ++position;
            if (position == cache_count) return -1;
            const std::size_t slot = order[position];
            const auto cached_value = values[slot];
            for (std::size_t index = position; index + 1 < cache_count; ++index)
                order[index] = order[index + 1];
            order[cache_count - 1] = slot;
            append(records, record_count, 1);
            append(records, record_count, 1);
            append(records, record_count, cached_value);
        } else {
            return -1;
        }
    }
    append(records, record_count, 2);
    append(records, record_count, static_cast<std::int64_t>(cache_count));
    for (std::size_t index = 0; index < cache_count; ++index) {
        const auto slot = order[index];
        append(records, record_count, keys[slot]);
        append(records, record_count, values[slot]);
    }
    const std::size_t output_bytes = record_count * 8;
    if (output == nullptr || output_capacity < output_bytes) return -2;
    for (std::size_t index = 0; index < record_count; ++index)
        write_i64_le(output, index * 8, records[index]);
    return static_cast<std::int64_t>(output_bytes);
}
