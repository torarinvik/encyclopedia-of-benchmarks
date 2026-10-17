#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t max_elements = 16;

void insert_at_bottom(std::int64_t* items, std::size_t size, std::int64_t value) {
    if (size == 0) { items[0] = value; return; }
    const auto top = items[size - 1];
    insert_at_bottom(items, size - 1, value);
    items[size] = top;
}

void reverse_recursive(std::int64_t* items, std::size_t size) {
    if (size == 0) return;
    const auto top = items[size - 1];
    reverse_recursive(items, size - 1);
    insert_at_bottom(items, size - 1, top);
}

void put_i64_le(std::uint8_t* output, std::size_t offset, std::int64_t value) {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
}

extern "C" std::int64_t reverse_stack(const std::int64_t* input, std::size_t length,
                                        std::uint8_t* output, std::size_t capacity) noexcept {
    if (input == nullptr || length < 1) return -1;
    const auto raw_count = input[0];
    if (raw_count < 0 || raw_count > max_elements || length != static_cast<std::size_t>(raw_count) + 1) return -1;
    const auto count = static_cast<std::size_t>(raw_count);
    std::int64_t items[16]{};
    for (std::size_t i = 0; i < count; ++i) {
        if (input[i + 1] < -1000000 || input[i + 1] > 1000000) return -1;
        items[i] = input[i + 1];
    }
    const auto bytes = (count + 1) * 8;
    if (output == nullptr || capacity < bytes) return -2;
    reverse_recursive(items, count);
    put_i64_le(output, 0, raw_count);
    for (std::size_t i = 0; i < count; ++i) put_i64_le(output, 8 * (i + 1), items[i]);
    return static_cast<std::int64_t>(bytes);
}
