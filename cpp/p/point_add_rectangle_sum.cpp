#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_n = 32, max_q = 32, max_points = max_n + max_q;
constexpr std::size_t max_parseable = 2 + 3 * max_n + 5 * max_q + 1;
constexpr std::int64_t max_coord = 1'000'000, max_weight = 1'000'000;
struct Point { std::int64_t x, y, weight; };
struct Operation { std::int64_t kind, a, b, c, d; };

std::size_t lowbit(std::size_t value) noexcept { return value & (~value + 1); }

std::size_t lower_bound_i64(const std::array<std::int64_t, max_points>& values,
                            std::size_t count, std::int64_t target) noexcept {
    std::size_t left = 0, right = count;
    while (left < right) {
        const auto middle = left + (right - left) / 2;
        if (values[middle] < target) left = middle + 1;
        else right = middle;
    }
    return left;
}

std::size_t lower_bound_size(const std::size_t* values, std::size_t count,
                             std::size_t target) noexcept {
    std::size_t left = 0, right = count;
    while (left < right) {
        const auto middle = left + (right - left) / 2;
        if (values[middle] < target) left = middle + 1;
        else right = middle;
    }
    return left;
}

std::size_t sort_unique(std::array<std::int64_t, max_points>& values,
                        std::size_t count) noexcept {
    for (std::size_t index = 1; index < count; ++index) {
        const auto value = values[index];
        auto position = index;
        while (position > 0 && values[position - 1] > value) {
            values[position] = values[position - 1];
            --position;
        }
        values[position] = value;
    }
    std::size_t unique_count = 0;
    for (std::size_t index = 0; index < count; ++index)
        if (unique_count == 0 || values[index] != values[unique_count - 1])
            values[unique_count++] = values[index];
    return unique_count;
}

void register_coordinate(const std::array<std::int64_t, max_points>& xs,
        std::size_t x_count, const std::array<std::int64_t, max_points>& ys,
        std::size_t y_count, std::array<bool, (max_points + 1) * max_points>& present,
        std::int64_t x, std::int64_t y) noexcept {
    auto outer = lower_bound_i64(xs, x_count, x) + 1;
    const auto rank = lower_bound_i64(ys, y_count, y);
    while (outer <= x_count) {
        present[outer * max_points + rank] = true;
        outer += lowbit(outer);
    }
}

void fenwick_add(std::array<std::int64_t, (max_points + 1) * (max_points + 1)>& tree,
        const std::array<std::size_t, (max_points + 1) * max_points>& y_values,
        const std::array<std::size_t, max_points + 1>& y_counts, std::size_t x_count,
        const std::array<std::int64_t, max_points>& xs,
        const std::array<std::int64_t, max_points>& ys, std::size_t y_count,
        std::int64_t x, std::int64_t y, std::int64_t weight) noexcept {
    auto outer = lower_bound_i64(xs, x_count, x) + 1;
    const auto y_rank = lower_bound_i64(ys, y_count, y);
    while (outer <= x_count) {
        const auto row = outer * max_points;
        auto inner = lower_bound_size(&y_values[row], y_counts[outer], y_rank) + 1;
        while (inner <= y_counts[outer]) {
            tree[outer * (max_points + 1) + inner] += weight;
            inner += lowbit(inner);
        }
        outer += lowbit(outer);
    }
}

std::int64_t prefix_sum(
        const std::array<std::int64_t, (max_points + 1) * (max_points + 1)>& tree,
        const std::array<std::size_t, (max_points + 1) * max_points>& y_values,
        const std::array<std::size_t, max_points + 1>& y_counts, std::size_t x_count,
        const std::array<std::int64_t, max_points>& xs,
        const std::array<std::int64_t, max_points>& ys, std::size_t y_count,
        std::int64_t x_limit, std::int64_t y_limit) noexcept {
    auto outer = lower_bound_i64(xs, x_count, x_limit);
    const auto y_limit_rank = lower_bound_i64(ys, y_count, y_limit);
    std::int64_t total = 0;
    while (outer > 0) {
        const auto row = outer * max_points;
        auto inner = lower_bound_size(&y_values[row], y_counts[outer], y_limit_rank);
        while (inner > 0) {
            total += tree[outer * (max_points + 1) + inner];
            inner -= lowbit(inner);
        }
        outer -= lowbit(outer);
    }
    return total;
}

void store_i64_le(std::uint8_t* output, std::size_t offset, std::int64_t value) noexcept {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
} // namespace

extern "C" std::int64_t point_add_rectangle_sum(const std::int64_t* input,
    std::size_t length, std::uint8_t* output, std::size_t capacity) noexcept {
    if (input == nullptr || length < 2 || length > max_parseable) return -1;
    const auto n_value = input[0], q_value = input[1];
    if (n_value < 1 || n_value > static_cast<std::int64_t>(max_n) ||
        q_value < 0 || q_value > static_cast<std::int64_t>(max_q)) return -1;
    const auto n = static_cast<std::size_t>(n_value), q = static_cast<std::size_t>(q_value);

    std::array<Point, max_n> initial{};
    std::array<Operation, max_q> operations{};
    std::array<std::int64_t, max_points> all_x{}, all_y{};
    std::size_t point_count = 0, cursor = 2;
    for (std::size_t index = 0; index < n; ++index) {
        if (cursor + 3 > length) return -1;
        const auto x = input[cursor++], y = input[cursor++], weight = input[cursor++];
        if (x < 0 || x > max_coord || y < 0 || y > max_coord ||
            weight < 0 || weight > max_weight) return -1;
        initial[index] = {x, y, weight};
        all_x[point_count] = x; all_y[point_count++] = y;
    }
    std::size_t query_count = 0;
    for (std::size_t index = 0; index < q; ++index) {
        if (cursor >= length) return -1;
        const auto kind = input[cursor++];
        if (kind == 0) {
            if (cursor + 3 > length) return -1;
            const auto x = input[cursor++], y = input[cursor++], weight = input[cursor++];
            if (x < 0 || x > max_coord || y < 0 || y > max_coord ||
                weight < 0 || weight > max_weight) return -1;
            operations[index] = {0, x, y, weight, 0};
            all_x[point_count] = x; all_y[point_count++] = y;
        } else if (kind == 1) {
            if (cursor + 4 > length) return -1;
            const auto left = input[cursor++], down = input[cursor++];
            const auto right = input[cursor++], up = input[cursor++];
            if (left < 0 || left >= right || right > max_coord ||
                down < 0 || down >= up || up > max_coord) return -1;
            operations[index] = {1, left, down, right, up};
            ++query_count;
        } else return -1;
    }
    if (cursor != length) return -1;

    const auto x_count = sort_unique(all_x, point_count);
    const auto y_count = sort_unique(all_y, point_count);
    std::array<bool, (max_points + 1) * max_points> present{};
    for (std::size_t index = 0; index < n; ++index)
        register_coordinate(all_x, x_count, all_y, y_count, present, initial[index].x, initial[index].y);
    for (std::size_t index = 0; index < q; ++index)
        if (operations[index].kind == 0)
            register_coordinate(all_x, x_count, all_y, y_count, present, operations[index].a, operations[index].b);

    std::array<std::size_t, (max_points + 1) * max_points> y_values{};
    std::array<std::size_t, max_points + 1> y_counts{};
    for (std::size_t outer = 1; outer <= x_count; ++outer)
        for (std::size_t rank = 0; rank < y_count; ++rank)
            if (present[outer * max_points + rank])
                y_values[outer * max_points + y_counts[outer]++] = rank;
    std::array<std::int64_t, (max_points + 1) * (max_points + 1)> tree{};
    for (std::size_t index = 0; index < n; ++index)
        fenwick_add(tree, y_values, y_counts, x_count, all_x, all_y, y_count,
                    initial[index].x, initial[index].y, initial[index].weight);

    std::array<std::int64_t, max_q> answers{};
    std::size_t answer_count = 0;
    for (std::size_t index = 0; index < q; ++index) {
        const auto op = operations[index];
        if (op.kind == 0) {
            fenwick_add(tree, y_values, y_counts, x_count, all_x, all_y, y_count, op.a, op.b, op.c);
        } else {
            answers[answer_count++] =
                prefix_sum(tree, y_values, y_counts, x_count, all_x, all_y, y_count, op.c, op.d) -
                prefix_sum(tree, y_values, y_counts, x_count, all_x, all_y, y_count, op.a, op.d) -
                prefix_sum(tree, y_values, y_counts, x_count, all_x, all_y, y_count, op.c, op.b) +
                prefix_sum(tree, y_values, y_counts, x_count, all_x, all_y, y_count, op.a, op.b);
        }
    }

    const auto output_bytes = 8 * answer_count;
    if (output_bytes > 0 && (output == nullptr || capacity < output_bytes)) return -2;
    for (std::size_t index = 0; index < answer_count; ++index)
        store_i64_le(output, 8 * index, answers[index]);
    return static_cast<std::int64_t>(output_bytes);
}
