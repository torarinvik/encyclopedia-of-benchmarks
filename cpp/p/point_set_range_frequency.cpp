#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MAX_N = 64, MAX_Q = 64, MAX_VALUES = MAX_N + MAX_Q;
constexpr std::size_t STRIDE = MAX_N + 1, MAX_TREE = MAX_VALUES * STRIDE;
constexpr std::size_t MAX_PARSEABLE_INPUT = 2 + MAX_N + 4 * MAX_Q + 1;
constexpr std::int64_t MAX_VALUE = 1'000'000;
struct Operation { std::int64_t kind{}, a{}, b{}, c{}; };

std::size_t lowbit(std::size_t value) { return value & (~value + 1); }

std::size_t lower_bound_i64(const std::array<std::int64_t, MAX_VALUES>& values,
                            std::size_t count, std::int64_t target) {
    std::size_t left = 0, right = count;
    while (left < right) {
        const auto middle = left + (right - left) / 2;
        if (values[middle] < target) left = middle + 1;
        else right = middle;
    }
    return left;
}

std::size_t sort_unique(std::array<std::int64_t, MAX_VALUES>& values, std::size_t count) {
    for (std::size_t i = 1; i < count; ++i) {
        const auto value = values[i];
        std::size_t position = i;
        while (position > 0 && values[position - 1] > value) {
            values[position] = values[position - 1];
            --position;
        }
        values[position] = value;
    }
    std::size_t unique_count = 0;
    for (std::size_t i = 0; i < count; ++i) {
        if (unique_count == 0 || values[i] != values[unique_count - 1])
            values[unique_count++] = values[i];
    }
    return unique_count;
}

void fenwick_add(std::array<std::int64_t, MAX_TREE>& tree, std::size_t value_id,
                 std::size_t position, std::size_t n, std::int64_t delta) {
    std::size_t index = position + 1;
    const std::size_t row = value_id * STRIDE;
    while (index <= n) {
        tree[row + index] += delta;
        index += lowbit(index);
    }
}

std::int64_t fenwick_prefix(const std::array<std::int64_t, MAX_TREE>& tree,
                            std::size_t value_id, std::size_t count) {
    std::int64_t total = 0;
    std::size_t index = count;
    const std::size_t row = value_id * STRIDE;
    while (index > 0) {
        total += tree[row + index];
        index -= lowbit(index);
    }
    return total;
}

void store_i64_le(std::uint8_t* output, std::size_t offset, std::int64_t value) {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
} // namespace

extern "C" std::int64_t point_set_range_frequency(const std::int64_t* input,
    std::size_t length, std::uint8_t* output, std::size_t capacity) {
    if (input == nullptr || length < 2 || length > MAX_PARSEABLE_INPUT) return -1;
    if (input[0] < 1 || input[0] > static_cast<std::int64_t>(MAX_N) ||
        input[1] < 0 || input[1] > static_cast<std::int64_t>(MAX_Q)) return -1;
    const auto n = static_cast<std::size_t>(input[0]);
    const auto q = static_cast<std::size_t>(input[1]);
    if (2 + n > length) return -1;
    std::array<std::int64_t, MAX_VALUES> values{};
    std::array<std::int64_t, MAX_N> initial{};
    std::array<Operation, MAX_Q> operations{};
    std::size_t value_count = 0;
    for (std::size_t i = 0; i < n; ++i) {
        const auto value = input[2 + i];
        if (value < 0 || value > MAX_VALUE) return -1;
        initial[i] = value;
        values[value_count++] = value;
    }
    std::size_t cursor = 2 + n, query_count = 0;
    for (std::size_t i = 0; i < q; ++i) {
        if (cursor >= length) return -1;
        const auto kind = input[cursor++];
        if (kind == 0) {
            if (cursor + 2 > length) return -1;
            const auto index = input[cursor], value = input[cursor + 1];
            cursor += 2;
            if (index < 0 || index >= static_cast<std::int64_t>(n) || value < 0 || value > MAX_VALUE) return -1;
            operations[i] = {kind, index, value, 0};
            values[value_count++] = value;
        } else if (kind == 1) {
            if (cursor + 3 > length) return -1;
            const auto left = input[cursor], right = input[cursor + 1], value = input[cursor + 2];
            cursor += 3;
            if (left < 0 || left > right || right > static_cast<std::int64_t>(n) || value < 0 || value > MAX_VALUE) return -1;
            operations[i] = {kind, left, right, value};
            ++query_count;
        } else return -1;
    }
    if (cursor != length) return -1;
    const std::size_t output_bytes = 8 * query_count;
    if (output_bytes > 0 && (output == nullptr || capacity < output_bytes)) return -2;

    const auto unique_count = sort_unique(values, value_count);
    std::array<std::int64_t, MAX_TREE> tree{};
    std::array<std::size_t, MAX_N> current{};
    for (std::size_t i = 0; i < n; ++i) {
        current[i] = lower_bound_i64(values, unique_count, initial[i]);
        fenwick_add(tree, current[i], i, n, 1);
    }
    std::size_t answer = 0;
    for (std::size_t i = 0; i < q; ++i) {
        const auto& operation = operations[i];
        if (operation.kind == 0) {
            const auto index = static_cast<std::size_t>(operation.a);
            const auto next = lower_bound_i64(values, unique_count, operation.b);
            if (current[index] != next) {
                fenwick_add(tree, current[index], index, n, -1);
                fenwick_add(tree, next, index, n, 1);
                current[index] = next;
            }
        } else {
            const auto id = lower_bound_i64(values, unique_count, operation.c);
            std::int64_t count = 0;
            if (id < unique_count && values[id] == operation.c)
                count = fenwick_prefix(tree, id, static_cast<std::size_t>(operation.b)) -
                        fenwick_prefix(tree, id, static_cast<std::size_t>(operation.a));
            store_i64_le(output, 8 * answer++, count);
        }
    }
    return static_cast<std::int64_t>(output_bytes);
}
