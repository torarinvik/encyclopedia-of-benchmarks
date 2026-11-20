#include <array>
#include <algorithm>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_n = 8;
constexpr std::size_t max_q = 32;
constexpr std::size_t max_input_length = 195;

struct RectangleQuery {
    std::size_t top;
    std::size_t left;
    std::size_t bottom;
    std::size_t right;
    std::size_t index;
};

bool query_before(const RectangleQuery& a, const RectangleQuery& b, std::size_t block_size) {
    const std::array<std::size_t, 4> a_blocks = {
        a.top / block_size, a.left / block_size, a.bottom / block_size, a.right / block_size};
    const std::array<std::size_t, 4> b_blocks = {
        b.top / block_size, b.left / block_size, b.bottom / block_size, b.right / block_size};
    if (a_blocks != b_blocks)
        return std::lexicographical_compare(a_blocks.begin(), a_blocks.end(), b_blocks.begin(), b_blocks.end());
    const std::array<std::size_t, 5> a_coordinates = {a.top, a.left, a.bottom, a.right, a.index};
    const std::array<std::size_t, 5> b_coordinates = {b.top, b.left, b.bottom, b.right, b.index};
    return std::lexicographical_compare(a_coordinates.begin(), a_coordinates.end(),
                                        b_coordinates.begin(), b_coordinates.end());
}

void add_value(std::int64_t value, std::array<std::int64_t, 8>& frequency, std::int64_t& sum_squares) {
    sum_squares += 2 * frequency[static_cast<std::size_t>(value)] + 1;
    ++frequency[static_cast<std::size_t>(value)];
}

void remove_value(std::int64_t value, std::array<std::int64_t, 8>& frequency, std::int64_t& sum_squares) {
    sum_squares += 1 - 2 * frequency[static_cast<std::size_t>(value)];
    --frequency[static_cast<std::size_t>(value)];
}
}

extern "C" std::int64_t mo_2d_rectangle_frequency_square(const std::int64_t* input,
                                                         std::size_t length) noexcept {
    if (input == nullptr || length < 2 || length > max_input_length) return -1;
    const auto n_value = input[0];
    const auto q_value = input[1];
    if (n_value < 1 || n_value > static_cast<std::int64_t>(max_n) ||
        q_value < 0 || q_value > static_cast<std::int64_t>(max_q)) return -1;

    const auto n = static_cast<std::size_t>(n_value);
    const auto q = static_cast<std::size_t>(q_value);
    const auto matrix_length = n * n;
    if (length != 2 + matrix_length + 4 * q) return -1;

    std::array<std::int64_t, max_n * max_n> matrix{};
    for (std::size_t cell = 0; cell < matrix_length; ++cell) {
        const auto value = input[2 + cell];
        if (value < 0 || value > 7) return -1;
        matrix[cell] = value;
    }

    std::array<RectangleQuery, max_q> queries{};
    const auto query_offset = 2 + matrix_length;
    for (std::size_t query = 0; query < q; ++query) {
        const auto top = input[query_offset + 4 * query];
        const auto left = input[query_offset + 4 * query + 1];
        const auto bottom = input[query_offset + 4 * query + 2];
        const auto right = input[query_offset + 4 * query + 3];
        if (top < 0 || left < 0 || bottom < top || right < left ||
            bottom >= n_value || right >= n_value) return -1;
        queries[query] = {static_cast<std::size_t>(top), static_cast<std::size_t>(left),
                          static_cast<std::size_t>(bottom), static_cast<std::size_t>(right), query};
    }

    std::size_t block_size = 0;
    const auto n_fourth = n * n * n * n;
    for (std::size_t candidate = 1; candidate <= n; ++candidate) {
        const auto candidate_fourth = candidate * candidate * candidate * candidate;
        if (q * candidate_fourth <= n_fourth) block_size = candidate;
    }
    if (block_size == 0) block_size = 1;

    for (std::size_t query = 1; query < q; ++query) {
        const auto current = queries[query];
        auto position = query;
        while (position > 0 && query_before(current, queries[position - 1], block_size)) {
            queries[position] = queries[position - 1];
            --position;
        }
        queries[position] = current;
    }
    if (q == 0) return 0;

    std::array<std::int64_t, 8> frequency{};
    std::int64_t sum_squares = 0;
    auto current = queries[0];
    for (std::size_t row = current.top; row <= current.bottom; ++row)
        for (std::size_t column = current.left; column <= current.right; ++column)
            add_value(matrix[row * n + column], frequency, sum_squares);

    std::array<std::int64_t, max_q> answers{};
    answers[current.index] = sum_squares;
    for (std::size_t query = 1; query < q; ++query) {
        const auto target = queries[query];
        while (current.top > target.top) {
            --current.top;
            for (std::size_t column = current.left; column <= current.right; ++column)
                add_value(matrix[current.top * n + column], frequency, sum_squares);
        }
        while (current.bottom < target.bottom) {
            ++current.bottom;
            for (std::size_t column = current.left; column <= current.right; ++column)
                add_value(matrix[current.bottom * n + column], frequency, sum_squares);
        }
        while (current.left > target.left) {
            --current.left;
            for (std::size_t row = current.top; row <= current.bottom; ++row)
                add_value(matrix[row * n + current.left], frequency, sum_squares);
        }
        while (current.right < target.right) {
            ++current.right;
            for (std::size_t row = current.top; row <= current.bottom; ++row)
                add_value(matrix[row * n + current.right], frequency, sum_squares);
        }
        while (current.top < target.top) {
            for (std::size_t column = current.left; column <= current.right; ++column)
                remove_value(matrix[current.top * n + column], frequency, sum_squares);
            ++current.top;
        }
        while (current.bottom > target.bottom) {
            for (std::size_t column = current.left; column <= current.right; ++column)
                remove_value(matrix[current.bottom * n + column], frequency, sum_squares);
            --current.bottom;
        }
        while (current.left < target.left) {
            for (std::size_t row = current.top; row <= current.bottom; ++row)
                remove_value(matrix[row * n + current.left], frequency, sum_squares);
            ++current.left;
        }
        while (current.right > target.right) {
            for (std::size_t row = current.top; row <= current.bottom; ++row)
                remove_value(matrix[row * n + current.right], frequency, sum_squares);
            --current.right;
        }
        answers[target.index] = sum_squares;
    }

    std::int64_t result = 0;
    for (std::size_t query = 0; query < q; ++query)
        result += static_cast<std::int64_t>(query + 1) * answers[query];
    return result;
}
