#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_input_length = 98;
constexpr std::size_t max_output_fields = 594;
constexpr std::int64_t min_value = -1000000;
constexpr std::int64_t max_value = 1000000;

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

extern "C" std::int64_t table_list(const std::int64_t *input, std::size_t length,
                                    std::uint8_t *output, std::size_t output_capacity)
{
    if (input == nullptr || length < 1 || length > max_input_length) return -1;
    const std::int64_t operation_count = input[0];
    if (operation_count < 0 || operation_count > 32
        || length != 1 + 3 * static_cast<std::size_t>(operation_count)) return -1;

    std::int64_t items[64]{};
    std::int64_t records[max_output_fields];
    std::size_t head = 32, item_count = 0, record_count = 0, cursor = 1;
    for (std::int64_t step = 0; step < operation_count; ++step) {
        const auto opcode = input[cursor++];
        const auto arg1 = input[cursor++];
        const auto arg2 = input[cursor++];
        switch (opcode) {
        case 0:
            if (arg1 < min_value || arg1 > max_value || arg2 != 0 || item_count >= 32) return -1;
            items[--head] = arg1;
            ++item_count;
            append(records, record_count, opcode); append(records, record_count, 0);
            break;
        case 1:
            if (arg1 < min_value || arg1 > max_value || arg2 != 0 || item_count >= 32) return -1;
            items[head + item_count++] = arg1;
            append(records, record_count, opcode); append(records, record_count, 0);
            break;
        case 2:
            if (arg1 != 0 || arg2 != 0) return -1;
            append(records, record_count, opcode);
            if (item_count == 0) append(records, record_count, 0);
            else { append(records, record_count, 1); append(records, record_count, items[head++]); --item_count; }
            break;
        case 3:
            if (arg1 != 0 || arg2 != 0) return -1;
            append(records, record_count, opcode);
            if (item_count == 0) append(records, record_count, 0);
            else { append(records, record_count, 1); append(records, record_count, items[head + --item_count]); }
            break;
        case 4:
        case 5:
            if (arg1 != 0 || arg2 != 0) return -1;
            append(records, record_count, opcode);
            if (item_count == 0) append(records, record_count, 0);
            else {
                append(records, record_count, 1);
                append(records, record_count, opcode == 4 ? items[head] : items[head + item_count - 1]);
            }
            break;
        case 6:
            if (arg2 != 0 || arg1 < 1 || static_cast<std::uint64_t>(arg1) > item_count) return -1;
            append(records, record_count, opcode); append(records, record_count, 1);
            append(records, record_count, items[head + static_cast<std::size_t>(arg1) - 1]);
            break;
        case 7:
            if (arg1 < 1 || static_cast<std::uint64_t>(arg1) > item_count || arg2 < min_value || arg2 > max_value) return -1;
            items[head + static_cast<std::size_t>(arg1) - 1] = arg2;
            append(records, record_count, opcode); append(records, record_count, 0);
            break;
        case 8:
            if (arg1 < -1 || arg1 > 33 || arg2 != 0) return -1;
            append(records, record_count, opcode); append(records, record_count, 1);
            append(records, record_count, arg1 >= 1 && static_cast<std::uint64_t>(arg1) <= item_count ? 1 : 0);
            break;
        case 9:
            if (arg1 != 0 || arg2 != 0) return -1;
            append(records, record_count, opcode); append(records, record_count, 1);
            append(records, record_count, static_cast<std::int64_t>(item_count));
            break;
        case 10:
        case 11:
            if (arg1 != 0 || arg2 != 0) return -1;
            append(records, record_count, opcode); append(records, record_count, static_cast<std::int64_t>(item_count));
            for (std::size_t index = 0; index < item_count; ++index) {
                const auto logical = opcode == 10 ? index + 1 : item_count - index;
                append(records, record_count, static_cast<std::int64_t>(logical));
                append(records, record_count, items[head + logical - 1]);
            }
            break;
        default: return -1;
        }
    }
    append(records, record_count, 12); append(records, record_count, static_cast<std::int64_t>(item_count));
    for (std::size_t index = 0; index < item_count; ++index) append(records, record_count, items[head + index]);

    const std::size_t output_bytes = record_count * 8;
    if (output == nullptr || output_capacity < output_bytes) return -2;
    for (std::size_t index = 0; index < record_count; ++index) write_i64_le(output, index * 8, records[index]);
    return static_cast<std::int64_t>(output_bytes);
}
