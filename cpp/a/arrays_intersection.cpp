// Count three-array occurrences and emit keys with total count exactly three.
#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t array_count = 3;
constexpr std::size_t max_array_length = 64;
constexpr std::size_t max_input_length = array_count * (max_array_length + 1);
constexpr std::size_t max_occurrences = array_count * max_array_length;
constexpr std::size_t table_size = 257;
constexpr std::size_t bytes_per_value = 4;

void add_occurrence(std::int64_t value, std::array<std::int64_t, table_size>& keys,
                    std::array<std::size_t, table_size>& counts,
                    std::array<bool, table_size>& occupied,
                    std::array<std::size_t, max_occurrences>& order,
                    std::size_t& order_length) noexcept {
    auto remainder = value % static_cast<std::int64_t>(table_size);
    if (remainder < 0) remainder += static_cast<std::int64_t>(table_size);
    auto slot = static_cast<std::size_t>(remainder);
    while (occupied[slot] && keys[slot] != value) slot = (slot + 1) % table_size;
    if (!occupied[slot]) {
        occupied[slot] = true;
        keys[slot] = value;
        counts[slot] = 0;
        order[order_length++] = slot;
    }
    ++counts[slot];
}

void store_i32_le(std::uint8_t* output, std::size_t position, std::int64_t value) noexcept {
    const auto bits = static_cast<std::uint32_t>(static_cast<std::int32_t>(value));
    for (std::size_t byte = 0; byte < bytes_per_value; ++byte)
        output[position + byte] = static_cast<std::uint8_t>(bits >> (byte * 8));
}
}

extern "C" std::int64_t arrays_intersection(const std::int64_t* input, std::size_t length,
    std::uint8_t* output, std::size_t output_capacity) noexcept {
    if (input == nullptr || length < array_count || length > max_input_length) return -1;
    std::array<std::size_t, array_count> starts{}, sizes{};
    std::size_t position = 0;
    for (std::size_t array = 0; array < array_count; ++array) {
        if (position >= length || input[position] < 0 || input[position] > static_cast<std::int64_t>(max_array_length)) return -1;
        const auto size = static_cast<std::size_t>(input[position++]);
        if (size > length - position) return -1;
        starts[array] = position;
        sizes[array] = size;
        for (std::size_t index = 0; index < size; ++index)
            if (input[position + index] < INT32_MIN || input[position + index] > INT32_MAX) return -1;
        position += size;
    }
    if (position != length) return -1;

    std::array<std::int64_t, table_size> keys{};
    std::array<std::size_t, table_size> counts{};
    std::array<bool, table_size> occupied{};
    std::array<std::size_t, max_occurrences> order{};
    std::size_t order_length = 0;
    for (std::size_t array = 0; array < array_count; ++array)
        for (std::size_t index = 0; index < sizes[array]; ++index)
            add_occurrence(input[starts[array] + index], keys, counts, occupied, order, order_length);

    std::size_t match_count = 0;
    for (std::size_t index = 0; index < order_length; ++index)
        if (counts[order[index]] == array_count) ++match_count;
    const auto required = match_count * bytes_per_value;
    if (output_capacity < required || (match_count > 0 && output == nullptr)) return -2;
    std::size_t written = 0;
    for (std::size_t index = 0; index < order_length; ++index) {
        const auto slot = order[index];
        if (counts[slot] == array_count) store_i32_le(output, written++ * bytes_per_value, keys[slot]);
    }
    return static_cast<std::int64_t>(written);
}
