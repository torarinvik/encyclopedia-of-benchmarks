#include <cstddef>
#include <cstdint>
#include <cstring>

namespace {
constexpr std::size_t max_nodes = 128;
constexpr std::size_t max_output = 3589;
std::size_t append_i64(std::uint8_t *buffer, std::size_t position, std::int64_t value) {
    std::uint8_t reversed[20];
    std::size_t length = 0;
    std::uint64_t magnitude = value < 0
        ? static_cast<std::uint64_t>(-(value + 1)) + 1
        : static_cast<std::uint64_t>(value);
    do { reversed[length++] = static_cast<std::uint8_t>('0' + magnitude % 10); magnitude /= 10; }
    while (magnitude != 0);
    buffer[position++] = '<';
    if (value < 0) buffer[position++] = '-';
    while (length > 0) buffer[position++] = reversed[--length];
    buffer[position++] = '>';
    std::memcpy(buffer + position, " ---> ", 6);
    return position + 6;
}
}

extern "C" std::int64_t from_sequence(const std::int64_t *input, std::size_t length,
                                       std::uint8_t *output, std::size_t capacity) {
    if (!input || length < 2 || length > max_nodes + 1) return -1;
    const std::int64_t count = input[0];
    if (count < 1 || count > static_cast<std::int64_t>(max_nodes)
        || length != static_cast<std::size_t>(count + 1)) return -1;
    std::uint8_t buffer[max_output];
    std::size_t position = 0;
    for (std::int64_t i = 0; i < count; ++i) position = append_i64(buffer, position, input[i + 1]);
    std::memcpy(buffer + position, "<END>", 5);
    position += 5;
    if (!output || capacity < position) return -2;
    std::memcpy(output, buffer, position);
    return static_cast<std::int64_t>(position);
}
