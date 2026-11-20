/* Two-stack aggregate deque with midpoint rebuilding. */
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_operations = 32;
constexpr std::size_t max_input_length = 162;
constexpr std::int64_t modulus = 97;
struct Matrix { std::int64_t v[4]; };

Matrix identity() noexcept { return {{1, 0, 0, 1}}; }

Matrix multiply(const Matrix &x, const Matrix &y) noexcept {
    return {{(x.v[0] * y.v[0] + x.v[1] * y.v[2]) % modulus,
             (x.v[0] * y.v[1] + x.v[1] * y.v[3]) % modulus,
             (x.v[2] * y.v[0] + x.v[3] * y.v[2]) % modulus,
             (x.v[2] * y.v[1] + x.v[3] * y.v[3]) % modulus}};
}

std::int64_t pack(const Matrix &matrix) noexcept {
    return matrix.v[0] + modulus * matrix.v[1] + modulus * modulus * matrix.v[2]
        + modulus * modulus * modulus * matrix.v[3];
}

void push_front(Matrix *items, Matrix *aggregates, std::size_t &count, const Matrix &value) noexcept {
    items[count] = value;
    aggregates[count] = count == 0 ? value : multiply(value, aggregates[count - 1]);
    ++count;
}

void push_back(Matrix *items, Matrix *aggregates, std::size_t &count, const Matrix &value) noexcept {
    items[count] = value;
    aggregates[count] = count == 0 ? value : multiply(aggregates[count - 1], value);
    ++count;
}

void rebalance(Matrix *front, Matrix *front_aggregate, std::size_t &front_count,
               Matrix *back, Matrix *back_aggregate, std::size_t &back_count,
               Matrix *temporary) noexcept {
    const bool front_was_empty = front_count == 0;
    const auto total = front_count + back_count;
    for (std::size_t i = 0; i < front_count; ++i) temporary[i] = front[front_count - 1 - i];
    for (std::size_t i = 0; i < back_count; ++i) temporary[front_count + i] = back[i];
    const auto front_size = total / 2 + (front_was_empty ? total % 2 : 0);
    front_count = 0;
    back_count = 0;
    for (std::size_t i = front_size; i > 0; --i) push_front(front, front_aggregate, front_count, temporary[i - 1]);
    for (std::size_t i = front_size; i < total; ++i) push_back(back, back_aggregate, back_count, temporary[i]);
}
}

extern "C" std::int64_t slide_window_aggregation_deque(const std::int64_t *input, std::size_t length) noexcept {
    if (input == nullptr || length < 1 || length > max_input_length) return -1;
    const auto operation_count_value = input[0];
    if (operation_count_value < 0 || operation_count_value > static_cast<std::int64_t>(max_operations)) return -1;
    const auto operation_count = static_cast<std::size_t>(operation_count_value);
    Matrix front[max_operations], front_aggregate[max_operations];
    Matrix back[max_operations], back_aggregate[max_operations];
    Matrix temporary[max_operations];
    std::size_t front_count = 0, back_count = 0, cursor = 1, query_ordinal = 0;
    std::int64_t checksum = 0;
    for (std::size_t operation = 0; operation < operation_count; ++operation) {
        if (cursor >= length) return -1;
        const auto opcode = input[cursor++];
        if (opcode == 0 || opcode == 1) {
            if (cursor + 4 > length) return -1;
            Matrix value{};
            for (std::size_t i = 0; i < 4; ++i) {
                if (input[cursor + i] < 0 || input[cursor + i] >= modulus) return -1;
                value.v[i] = input[cursor + i];
            }
            cursor += 4;
            if (opcode == 0) push_front(front, front_aggregate, front_count, value);
            else push_back(back, back_aggregate, back_count, value);
        } else if (opcode == 2 || opcode == 3) {
            if (front_count + back_count == 0) return -1;
            if (opcode == 2) {
                if (front_count == 0) rebalance(front, front_aggregate, front_count, back, back_aggregate, back_count, temporary);
                --front_count;
            } else {
                if (back_count == 0) rebalance(front, front_aggregate, front_count, back, back_aggregate, back_count, temporary);
                --back_count;
            }
        } else if (opcode == 4) {
            const auto left = front_count == 0 ? identity() : front_aggregate[front_count - 1];
            const auto right = back_count == 0 ? identity() : back_aggregate[back_count - 1];
            ++query_ordinal;
            checksum += static_cast<std::int64_t>(query_ordinal) * (pack(multiply(left, right)) + 1);
        } else return -1;
    }
    return cursor == length ? checksum : -1;
}
