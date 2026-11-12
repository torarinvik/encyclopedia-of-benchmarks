#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MAX_N = 32;
constexpr std::size_t MAX_Q = 32;
constexpr std::size_t MAX_RECTANGLES = MAX_N + MAX_Q;
constexpr std::size_t MAX_COORDS = 2 * MAX_RECTANGLES;
constexpr std::size_t MAX_CORNERS = 4 * MAX_RECTANGLES;
constexpr std::size_t MAX_PARSEABLE_INPUT = 2 + 5 * MAX_N + 6 * MAX_Q + 1;
constexpr std::int64_t MAX_COORD = 1'000'000;
constexpr std::int64_t MAX_WEIGHT = 1'000'000;

struct Rectangle { std::int64_t left{}, down{}, right{}, up{}, weight{}; };
struct Operation { std::int64_t kind{}, a{}, b{}, c{}, d{}, e{}; };

std::size_t lowbit(std::size_t value) { return value & (~value + 1); }

std::size_t lower_bound_i64(const std::array<std::int64_t, MAX_CORNERS>& values,
                            std::size_t count, std::int64_t target) {
    std::size_t left = 0, right = count;
    while (left < right) {
        const std::size_t middle = left + (right - left) / 2;
        if (values[middle] < target) left = middle + 1;
        else right = middle;
    }
    return left;
}

std::size_t upper_bound_i64(const std::array<std::int64_t, MAX_CORNERS>& values,
                            std::size_t count, std::int64_t target) {
    std::size_t left = 0, right = count;
    while (left < right) {
        const std::size_t middle = left + (right - left) / 2;
        if (values[middle] <= target) left = middle + 1;
        else right = middle;
    }
    return left;
}

std::size_t lower_bound_size(const std::array<std::size_t, (MAX_COORDS + 1) * MAX_COORDS>& values,
                             std::size_t offset, std::size_t count, std::size_t target) {
    std::size_t left = 0, right = count;
    while (left < right) {
        const std::size_t middle = left + (right - left) / 2;
        if (values[offset + middle] < target) left = middle + 1;
        else right = middle;
    }
    return left;
}

std::size_t sort_unique(std::array<std::int64_t, MAX_CORNERS>& values,
                        std::size_t count) {
    for (std::size_t index = 1; index < count; ++index) {
        const auto value = values[index];
        std::size_t position = index;
        while (position > 0 && values[position - 1] > value) {
            values[position] = values[position - 1];
            --position;
        }
        values[position] = value;
    }
    std::size_t unique_count = 0;
    for (std::size_t index = 0; index < count; ++index) {
        if (unique_count == 0 || values[index] != values[unique_count - 1])
            values[unique_count++] = values[index];
    }
    return unique_count;
}

using Presence = std::array<bool, (MAX_COORDS + 1) * MAX_COORDS>;
using NestedValues = std::array<std::size_t, (MAX_COORDS + 1) * MAX_COORDS>;
using NestedTree = std::array<std::int64_t, (MAX_COORDS + 1) * (MAX_COORDS + 1)>;

void register_event(const std::array<std::int64_t, MAX_CORNERS>& xs, std::size_t x_count,
    const std::array<std::int64_t, MAX_CORNERS>& ys, std::size_t y_count,
    Presence& present, std::int64_t x, std::int64_t y) {
    std::size_t outer = lower_bound_i64(xs, x_count, x) + 1;
    const std::size_t rank = lower_bound_i64(ys, y_count, y);
    while (outer <= x_count) {
        present[outer * MAX_COORDS + rank] = true;
        outer += lowbit(outer);
    }
}

void register_rectangle(const std::array<std::int64_t, MAX_CORNERS>& xs,
    std::size_t x_count, const std::array<std::int64_t, MAX_CORNERS>& ys,
    std::size_t y_count, Presence& present, const Rectangle& rectangle) {
    register_event(xs, x_count, ys, y_count, present, rectangle.left, rectangle.down);
    register_event(xs, x_count, ys, y_count, present, rectangle.right, rectangle.down);
    register_event(xs, x_count, ys, y_count, present, rectangle.left, rectangle.up);
    register_event(xs, x_count, ys, y_count, present, rectangle.right, rectangle.up);
}

void fenwick_add(NestedTree& tree, const NestedValues& y_values,
    const std::array<std::size_t, MAX_COORDS + 1>& y_counts,
    const std::array<std::int64_t, MAX_CORNERS>& xs, std::size_t x_count,
    const std::array<std::int64_t, MAX_CORNERS>& ys, std::size_t y_count,
    std::int64_t x, std::int64_t y, std::int64_t weight) {
    std::size_t outer = lower_bound_i64(xs, x_count, x) + 1;
    const std::size_t y_rank = lower_bound_i64(ys, y_count, y);
    while (outer <= x_count) {
        const std::size_t row = outer * MAX_COORDS;
        std::size_t inner = lower_bound_size(y_values, row, y_counts[outer], y_rank) + 1;
        while (inner <= y_counts[outer]) {
            tree[outer * (MAX_COORDS + 1) + inner] += weight;
            inner += lowbit(inner);
        }
        outer += lowbit(outer);
    }
}

void apply_rectangle(NestedTree& tree, const NestedValues& y_values,
    const std::array<std::size_t, MAX_COORDS + 1>& y_counts,
    const std::array<std::int64_t, MAX_CORNERS>& xs, std::size_t x_count,
    const std::array<std::int64_t, MAX_CORNERS>& ys, std::size_t y_count,
    const Rectangle& rectangle) {
    const auto weight = rectangle.weight;
    fenwick_add(tree, y_values, y_counts, xs, x_count, ys, y_count,
                rectangle.left, rectangle.down, weight);
    fenwick_add(tree, y_values, y_counts, xs, x_count, ys, y_count,
                rectangle.right, rectangle.down, -weight);
    fenwick_add(tree, y_values, y_counts, xs, x_count, ys, y_count,
                rectangle.left, rectangle.up, -weight);
    fenwick_add(tree, y_values, y_counts, xs, x_count, ys, y_count,
                rectangle.right, rectangle.up, weight);
}

std::int64_t prefix_sum(const NestedTree& tree, const NestedValues& y_values,
    const std::array<std::size_t, MAX_COORDS + 1>& y_counts,
    const std::array<std::int64_t, MAX_CORNERS>& xs, std::size_t x_count,
    const std::array<std::int64_t, MAX_CORNERS>& ys, std::size_t y_count,
    std::int64_t x_limit, std::int64_t y_limit) {
    std::size_t outer = upper_bound_i64(xs, x_count, x_limit);
    const std::size_t y_limit_rank = upper_bound_i64(ys, y_count, y_limit);
    std::int64_t total = 0;
    while (outer > 0) {
        const std::size_t row = outer * MAX_COORDS;
        std::size_t inner = lower_bound_size(y_values, row, y_counts[outer], y_limit_rank);
        while (inner > 0) {
            total += tree[outer * (MAX_COORDS + 1) + inner];
            inner -= lowbit(inner);
        }
        outer -= lowbit(outer);
    }
    return total;
}

void store_i64_le(std::uint8_t* output, std::size_t offset, std::int64_t value) {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
} // namespace

extern "C" std::int64_t rectangle_add_point_get(const std::int64_t* input,
    std::size_t length, std::uint8_t* output, std::size_t capacity) {
    if (input == nullptr || length < 2 || length > MAX_PARSEABLE_INPUT) return -1;
    const auto n_value = input[0], q_value = input[1];
    if (n_value < 1 || n_value > static_cast<std::int64_t>(MAX_N) ||
        q_value < 1 || q_value > static_cast<std::int64_t>(MAX_Q)) return -1;
    const auto n = static_cast<std::size_t>(n_value);
    const auto q = static_cast<std::size_t>(q_value);
    std::array<Rectangle, MAX_N> initial{};
    std::array<Operation, MAX_Q> operations{};
    std::array<std::int64_t, MAX_CORNERS> all_x{}, all_y{};
    std::size_t rectangle_count = 0, cursor = 2;
    for (std::size_t index = 0; index < n; ++index) {
        if (cursor + 5 > length) return -1;
        const Rectangle rectangle{input[cursor], input[cursor + 1], input[cursor + 2],
                                  input[cursor + 3], input[cursor + 4]};
        cursor += 5;
        if (rectangle.left < 0 || rectangle.left >= rectangle.right || rectangle.right > MAX_COORD ||
            rectangle.down < 0 || rectangle.down >= rectangle.up || rectangle.up > MAX_COORD ||
            rectangle.weight < 0 || rectangle.weight > MAX_WEIGHT) return -1;
        initial[index] = rectangle;
        const std::array<std::int64_t, 4> corner_x{
            rectangle.left, rectangle.right, rectangle.left, rectangle.right};
        const std::array<std::int64_t, 4> corner_y{
            rectangle.down, rectangle.down, rectangle.up, rectangle.up};
        for (std::size_t corner = 0; corner < 4; ++corner) {
            all_x[rectangle_count * 4 + corner] = corner_x[corner];
            all_y[rectangle_count * 4 + corner] = corner_y[corner];
        }
        ++rectangle_count;
    }
    for (std::size_t index = 0; index < q; ++index) {
        if (cursor >= length) return -1;
        const auto kind = input[cursor++];
        if (kind == 0) {
            if (cursor + 5 > length) return -1;
            const Rectangle rectangle{input[cursor], input[cursor + 1], input[cursor + 2],
                                      input[cursor + 3], input[cursor + 4]};
            cursor += 5;
            if (rectangle.left < 0 || rectangle.left >= rectangle.right || rectangle.right > MAX_COORD ||
                rectangle.down < 0 || rectangle.down >= rectangle.up || rectangle.up > MAX_COORD ||
                rectangle.weight < 0 || rectangle.weight > MAX_WEIGHT) return -1;
            operations[index] = {0, rectangle.left, rectangle.down, rectangle.right,
                                 rectangle.up, rectangle.weight};
            const std::array<std::int64_t, 4> corner_x{
                rectangle.left, rectangle.right, rectangle.left, rectangle.right};
            const std::array<std::int64_t, 4> corner_y{
                rectangle.down, rectangle.down, rectangle.up, rectangle.up};
            for (std::size_t corner = 0; corner < 4; ++corner) {
                all_x[rectangle_count * 4 + corner] = corner_x[corner];
                all_y[rectangle_count * 4 + corner] = corner_y[corner];
            }
            ++rectangle_count;
        } else if (kind == 1) {
            if (cursor + 2 > length) return -1;
            const auto x = input[cursor++], y = input[cursor++];
            if (x < 0 || x > MAX_COORD || y < 0 || y > MAX_COORD) return -1;
            operations[index] = {1, x, y, 0, 0, 0};
        } else return -1;
    }
    if (cursor != length) return -1;

    const std::size_t corner_count = rectangle_count * 4;
    const std::size_t x_count = sort_unique(all_x, corner_count);
    const std::size_t y_count = sort_unique(all_y, corner_count);
    Presence present{};
    for (std::size_t index = 0; index < n; ++index)
        register_rectangle(all_x, x_count, all_y, y_count, present, initial[index]);
    for (std::size_t index = 0; index < q; ++index) if (operations[index].kind == 0) {
        const Rectangle rectangle{operations[index].a, operations[index].b,
            operations[index].c, operations[index].d, operations[index].e};
        register_rectangle(all_x, x_count, all_y, y_count, present, rectangle);
    }
    NestedValues y_values{};
    std::array<std::size_t, MAX_COORDS + 1> y_counts{};
    for (std::size_t outer = 1; outer <= x_count; ++outer)
        for (std::size_t rank = 0; rank < y_count; ++rank)
            if (present[outer * MAX_COORDS + rank])
                y_values[outer * MAX_COORDS + y_counts[outer]++] = rank;
    NestedTree tree{};
    for (std::size_t index = 0; index < n; ++index)
        apply_rectangle(tree, y_values, y_counts, all_x, x_count, all_y, y_count, initial[index]);
    std::array<std::int64_t, MAX_Q> answers{};
    std::size_t answer_count = 0;
    for (std::size_t index = 0; index < q; ++index) {
        const Operation operation = operations[index];
        if (operation.kind == 0) {
            const Rectangle rectangle{operation.a, operation.b, operation.c,
                                      operation.d, operation.e};
            apply_rectangle(tree, y_values, y_counts, all_x, x_count, all_y, y_count, rectangle);
        } else {
            answers[answer_count++] = prefix_sum(tree, y_values, y_counts,
                all_x, x_count, all_y, y_count, operation.a, operation.b);
        }
    }
    const std::size_t output_bytes = 8 * answer_count;
    if (output_bytes > 0 && (output == nullptr || capacity < output_bytes)) return -2;
    for (std::size_t index = 0; index < answer_count; ++index)
        store_i64_le(output, 8 * index, answers[index]);
    return static_cast<std::int64_t>(output_bytes);
}
