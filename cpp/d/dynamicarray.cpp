#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t op_limit = 128, item_limit = 64, input_limit = 1 + 3 * op_limit;
void store_i64(std::uint8_t *output, std::size_t index, std::int64_t value) {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) output[index * 8 + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
}

extern "C" std::int64_t dynamicarray(const std::int64_t *input, std::size_t length,
                                      std::uint8_t *output, std::size_t output_capacity) {
    if (!input || length < 1 || length > input_limit || input[0] < 0 || input[0] > static_cast<std::int64_t>(op_limit)) return -1;
    std::array<std::int64_t, item_limit> a{}, b{}, queries{};
    std::size_t size = 0, capacity = 0, cursor = 1, query_count = 0, active = 0;
    for (std::int64_t oi = 0; oi < input[0]; ++oi) {
        if (cursor >= length) return -1;
        const auto op = input[cursor++];
        if (op == 0) {
            if (cursor >= length || size >= item_limit) return -1;
            if (size == capacity) {
                if (active == 0) { for (std::size_t i = 0; i < size; ++i) b[i] = a[i]; active = 1; }
                else { for (std::size_t i = 0; i < size; ++i) a[i] = b[i]; active = 0; }
                capacity = capacity == 0 ? 10 : capacity * 2;
            }
            (active == 0 ? a : b)[size++] = input[cursor++];
        } else if (op == 1) {
            if (cursor + 1 >= length) return -1;
            const auto index = input[cursor++], value = input[cursor++];
            if (index < 0 || static_cast<std::uint64_t>(index) >= size) return -1;
            (active == 0 ? a : b)[static_cast<std::size_t>(index)] = value;
        } else if (op == 2 || op == 3) {
            if (cursor >= length) return -1;
            const auto index = input[cursor++];
            if (index < 0 || static_cast<std::uint64_t>(index) >= size) return -1;
            auto &data = active == 0 ? a : b;
            if (op == 2) { if (query_count >= op_limit) return -1; queries[query_count++] = data[static_cast<std::size_t>(index)]; }
            else { for (std::size_t i = static_cast<std::size_t>(index); i + 1 < size; ++i) data[i] = data[i + 1]; --size; }
        } else if (op >= 4 && op <= 6) {
            if (query_count >= op_limit) return -1;
            queries[query_count++] = op == 4 ? static_cast<std::int64_t>(size) : op == 5 ? static_cast<std::int64_t>(capacity) : (size == 0 ? 1 : 0);
        } else return -1;
    }
    if (cursor != length) return -1;
    const std::size_t words = 3 + query_count + size;
    if (!output || output_capacity < words * 8) return -2;
    store_i64(output, 0, static_cast<std::int64_t>(query_count));
    for (std::size_t i = 0; i < query_count; ++i) store_i64(output, i + 1, queries[i]);
    store_i64(output, query_count + 1, static_cast<std::int64_t>(size));
    store_i64(output, query_count + 2, static_cast<std::int64_t>(capacity));
    auto &data = active == 0 ? a : b;
    for (std::size_t i = 0; i < size; ++i) store_i64(output, query_count + 3 + i, data[i]);
    return static_cast<std::int64_t>(words);
}
