#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t min_capacity = 5;
constexpr std::size_t max_capacity = 31;
constexpr std::size_t max_insert_count = 3;
constexpr std::size_t max_parseable_input_length = 5;

void write_i64_le(char *output, std::size_t offset, std::int64_t value) noexcept
{
    std::uint64_t bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) {
        reinterpret_cast<unsigned char *>(output)[offset + byte] =
            static_cast<unsigned char>(bits & UINT64_C(0xff));
        bits >>= 8;
    }
}
}

extern "C" std::int64_t quadratic_probing(const std::int64_t *input,
                                           std::size_t input_length,
                                           char *output,
                                           std::size_t output_capacity) noexcept
{
    if (input == nullptr || input_length < 2 || input_length > max_parseable_input_length) return -1;

    const std::int64_t capacity_value = input[0];
    const std::int64_t insert_count_value = input[1];
    if (capacity_value < static_cast<std::int64_t>(min_capacity) ||
        capacity_value > static_cast<std::int64_t>(max_capacity) ||
        insert_count_value < 0 ||
        insert_count_value > static_cast<std::int64_t>(max_insert_count)) return -1;

    const std::size_t capacity = static_cast<std::size_t>(capacity_value);
    const std::size_t insert_count = static_cast<std::size_t>(insert_count_value);
    if (input_length != 2 + insert_count) return -1;

    for (std::size_t i = 0; i < insert_count; ++i) {
        if (input[2 + i] < 0) return -1;
    }

    std::int64_t table[max_capacity];
    for (std::size_t slot = 0; slot < capacity; ++slot) table[slot] = -1;

    for (std::size_t i = 0; i < insert_count; ++i) {
        const std::int64_t data = input[2 + i];
        const std::size_t home = static_cast<std::size_t>(data % static_cast<std::int64_t>(capacity));
        if (table[home] == -1) {
            table[home] = data;
            continue;
        }
        if (table[home] == data) continue;

        std::size_t probe = 1;
        std::size_t slot = (home + probe * probe) % capacity;
        while (table[slot] != -1 && table[slot] != static_cast<std::int64_t>(home)) {
            ++probe;
            slot = (home + probe * probe) % capacity;
        }
        table[slot] = data;
    }

    const std::size_t output_bytes = 8 * (capacity + 1);
    if (output == nullptr || output_capacity < output_bytes) return -2;
    write_i64_le(output, 0, static_cast<std::int64_t>(capacity));
    for (std::size_t slot = 0; slot < capacity; ++slot) {
        write_i64_le(output, 8 * (slot + 1), table[slot]);
    }
    return static_cast<std::int64_t>(output_bytes);
}
