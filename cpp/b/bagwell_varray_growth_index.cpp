/* Clean-room bounded Bagwell two-dimensional VArray profile. */
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_n = 321;
constexpr std::size_t max_q = 256;
constexpr std::size_t data_slots = 352;
constexpr std::size_t pointer_slots = 56;
constexpr std::size_t level_headers = 3;

struct Location { std::size_t pointer, base, offset; };

std::size_t level_start(std::size_t level) {
    constexpr std::size_t starts[3] = {0, 64, 320};
    return starts[level];
}

Location locate(std::size_t level, std::size_t index) {
    constexpr std::size_t value_start[3] = {0, 64, 320};
    constexpr std::size_t sides[3] = {8, 16, 32};
    constexpr std::size_t pointer_start[3] = {0, 8, 24};
    constexpr std::size_t data_start[3] = {0, 64, 320};
    const auto relative = index - value_start[level];
    const auto child = relative / sides[level];
    return {pointer_start[level] + child,
            data_start[level] + child * sides[level],
            relative % sides[level]};
}

std::int64_t find_level(std::size_t index, std::size_t current_header,
                        const std::int64_t previous_header[level_headers]) {
    auto level = static_cast<std::int64_t>(current_header);
    while (level >= 0 && index < level_start(static_cast<std::size_t>(level)))
        level = previous_header[static_cast<std::size_t>(level)];
    return level;
}

void put_i64_le(std::uint8_t *output, std::size_t offset, std::int64_t value) {
    const auto bits = static_cast<std::uint64_t>(value);
    for (unsigned byte = 0; byte < 8; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>(bits >> (byte * 8));
}
}

extern "C" std::int64_t bagwell_varray_growth_index(
    const std::int64_t *input, std::size_t length,
    std::uint8_t *output, std::size_t capacity) {
    if (input == nullptr || length < 2 || length > 580) return -1;
    const auto n_value = input[0], q_value = input[1];
    if (n_value < 0 || n_value > static_cast<std::int64_t>(max_n)
        || q_value < 0 || q_value > static_cast<std::int64_t>(max_q)) return -1;
    const auto n = static_cast<std::size_t>(n_value);
    const auto q = static_cast<std::size_t>(q_value);
    if ((n == 0 && q != 0) || length != 2 + n + q) return -1;
    const auto query_start = 2 + n;
    for (std::size_t j = 0; j < q; ++j)
        if (input[query_start + j] < 0
            || static_cast<std::uint64_t>(input[query_start + j]) >= n) return -1;

    std::int64_t data[data_slots] = {};
    std::int64_t pointers[pointer_slots];
    std::int64_t previous_header[level_headers] = {-1, -1, -1};
    std::size_t current_header = 0;
    for (auto &pointer : pointers) pointer = -1;
    for (std::size_t i = 0; i < n; ++i) {
        if (i == 64 || i == 320) {
            const auto next_header = current_header + 1;
            previous_header[next_header] = static_cast<std::int64_t>(current_header);
            current_header = next_header;
        }
        const auto location = locate(current_header, i);
        if (pointers[location.pointer] == -1)
            pointers[location.pointer] = static_cast<std::int64_t>(location.base);
        if (pointers[location.pointer] != static_cast<std::int64_t>(location.base)
            || location.base + location.offset >= data_slots) return -1;
        data[static_cast<std::size_t>(pointers[location.pointer]) + location.offset] = input[2 + i];
    }

    const auto output_bytes = 8 * (q + 1);
    if (output == nullptr || capacity < output_bytes) return -2;
    put_i64_le(output, 0, q_value);
    for (std::size_t j = 0; j < q; ++j) {
        const auto index = static_cast<std::size_t>(input[query_start + j]);
        const auto level = find_level(index, current_header, previous_header);
        const auto location = locate(static_cast<std::size_t>(level), index);
        put_i64_le(output, 8 * (j + 1),
                   data[static_cast<std::size_t>(pointers[location.pointer]) + location.offset]);
    }
    return static_cast<std::int64_t>(output_bytes);
}
