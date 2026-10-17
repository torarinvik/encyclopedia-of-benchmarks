#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_input_length = 130;
constexpr std::size_t max_operations = 64;
constexpr std::size_t max_list_length = 64;
constexpr std::size_t max_output_fields = 194;

void append_i64(std::int64_t *records, std::size_t &count, std::int64_t value)
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

extern "C" std::int64_t self_organizing_linked_list(
    const std::int64_t *input, std::size_t length, std::uint8_t *output,
    std::size_t output_capacity)
{
    if (input == nullptr || length < 1 || length > max_input_length) return -1;
    const auto operation_count = input[0];
    if (operation_count < 0 || operation_count > static_cast<std::int64_t>(max_operations)
        || length != 1 + 2 * static_cast<std::size_t>(operation_count)) return -1;

    std::int64_t items[max_list_length];
    std::int64_t records[max_output_fields];
    std::size_t item_count = 0, record_count = 0, cursor = 1;
    for (std::int64_t step = 0; step < operation_count; ++step) {
        const auto opcode = input[cursor++];
        const auto value = input[cursor++];
        if (value < INT32_MIN || value > INT32_MAX) return -1;
        if (opcode == 0) {
            if (item_count == max_list_length) return -1;
            items[item_count++] = value;
            append_i64(records, record_count, 0);
            append_i64(records, record_count, 0);
        } else if (opcode == 1) {
            std::size_t found_at = 0;
            while (found_at < item_count && items[found_at] != value) ++found_at;
            const std::int64_t found = found_at < item_count ? 1 : 0;
            append_i64(records, record_count, 1);
            append_i64(records, record_count, 1);
            append_i64(records, record_count, found);
            if (found != 0 && found_at != 0) {
                for (std::size_t index = found_at; index > 0; --index)
                    items[index] = items[index - 1];
                items[0] = value;
            }
        } else {
            return -1;
        }
    }
    append_i64(records, record_count, 2);
    append_i64(records, record_count, static_cast<std::int64_t>(item_count));
    for (std::size_t index = 0; index < item_count; ++index)
        append_i64(records, record_count, items[index]);

    const std::size_t output_bytes = record_count * 8;
    if (output == nullptr || output_capacity < output_bytes) return -2;
    for (std::size_t index = 0; index < record_count; ++index)
        write_i64_le(output, index * 8, records[index]);
    return static_cast<std::int64_t>(output_bytes);
}
