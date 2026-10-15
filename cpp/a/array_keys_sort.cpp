#include <cstddef>
#include <cstdint>
namespace {
void store_i64_le(std::uint8_t* output, std::size_t offset, std::int64_t value) {
    std::uint64_t bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) { output[offset + byte] = static_cast<std::uint8_t>(bits & 0xffu); bits >>= 8; }
}
int compare_rows(const std::int64_t* left, const std::int64_t* right, const std::int64_t* keys, std::size_t key_count, bool ascending) {
    for (std::size_t key = 0; key < key_count; ++key) {
        const auto a = left[keys[key] - 1], b = right[keys[key] - 1];
        if (a < b) return ascending ? -1 : 1;
        if (a > b) return ascending ? 1 : -1;
    }
    return 0;
}
}
extern "C" std::int64_t array_keys_sort(const std::int64_t* values, std::size_t length, std::uint8_t* output, std::size_t capacity) noexcept {
    if (values == nullptr || length < 8 || length > 263) return -1;
    const auto raw_count = values[0], raw_key_count = values[1], order = values[2];
    if (raw_count < 1 || raw_count > 64 || raw_key_count < 1 || raw_key_count > 4 || (order != 0 && order != 1)) return -1;
    const auto count = static_cast<std::size_t>(raw_count), key_count = static_cast<std::size_t>(raw_key_count);
    if (length != 3 + key_count + 4 * count) return -1;
    const auto* keys = values + 3;
    for (std::size_t i = 0; i < key_count; ++i) {
        if (keys[i] < 1 || keys[i] > 4) return -1;
        for (std::size_t j = 0; j < i; ++j) if (keys[i] == keys[j]) return -1;
    }
    std::int64_t rows[256]{};
    const std::size_t rows_start = 3 + key_count;
    for (std::size_t i = 0; i < 4 * count; ++i) {
        const auto value = values[rows_start + i];
        if (value < -1000 || value > 1000) return -1;
        rows[i] = value;
    }
    for (std::size_t i = 0; i < count; ++i) for (std::size_t j = i + 1; j < count; ++j)
        if (compare_rows(&rows[i * 4], &rows[j * 4], keys, key_count, true) == 0) return -1;
    const std::size_t byte_count = 32 * count;
    if (output == nullptr || capacity < byte_count) return -2;
    for (std::size_t i = 1; i < count; ++i) {
        std::int64_t temp[4];
        for (std::size_t column = 0; column < 4; ++column) temp[column] = rows[i * 4 + column];
        std::size_t position = i;
        while (position > 0 && compare_rows(&rows[(position - 1) * 4], temp, keys, key_count, order == 1) > 0) {
            for (std::size_t column = 0; column < 4; ++column) rows[position * 4 + column] = rows[(position - 1) * 4 + column];
            --position;
        }
        for (std::size_t column = 0; column < 4; ++column) rows[position * 4 + column] = temp[column];
    }
    for (std::size_t i = 0; i < 4 * count; ++i) store_i64_le(output, 8 * i, rows[i]);
    return static_cast<std::int64_t>(byte_count);
}
