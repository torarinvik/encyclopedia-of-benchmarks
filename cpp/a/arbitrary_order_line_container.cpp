/* Arbitrary-order line envelope with integer intersection breakpoints. */
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MAX_OPERATIONS = 32;
constexpr std::size_t MAX_INPUT_LENGTH = 99;
constexpr std::int64_t BREAKPOINT_INFINITY = INT64_C(1000000000000000);
constexpr std::int64_t CHECKSUM_OFFSET = INT64_C(2000001);
struct Line { std::int64_t slope, intercept, breakpoint; };

std::int64_t floor_div(std::int64_t numerator, std::int64_t denominator) noexcept {
    auto quotient = numerator / denominator;
    if (numerator % denominator != 0 && numerator < 0) --quotient;
    return quotient;
}

std::int64_t intersection(const Line &left, const Line &right) noexcept {
    return floor_div(left.intercept - right.intercept, right.slope - left.slope);
}

void erase_line(Line *lines, std::size_t &count, std::size_t position) noexcept {
    for (std::size_t i = position; i + 1 < count; ++i) lines[i] = lines[i + 1];
    --count;
}

void insert_line(Line *lines, std::size_t &count,
                 std::int64_t slope, std::int64_t intercept) noexcept {
    std::size_t position = 0;
    while (position < count && lines[position].slope < slope) ++position;
    if (position < count && lines[position].slope == slope) {
        if (lines[position].intercept >= intercept) return;
        erase_line(lines, count, position);
    }
    for (std::size_t i = count; i > position; --i) lines[i] = lines[i - 1];
    lines[position] = {slope, intercept, BREAKPOINT_INFINITY};
    ++count;
    std::size_t active = position;
    while (active + 1 < count) {
        const auto breakpoint = intersection(lines[active], lines[active + 1]);
        lines[active].breakpoint = breakpoint;
        if (breakpoint >= lines[active + 1].breakpoint) erase_line(lines, count, active + 1);
        else break;
    }
    if (active + 1 == count) lines[active].breakpoint = BREAKPOINT_INFINITY;
    if (active > 0) {
        const auto breakpoint = intersection(lines[active - 1], lines[active]);
        lines[active - 1].breakpoint = breakpoint;
        std::size_t cursor;
        if (breakpoint >= lines[active].breakpoint) {
            erase_line(lines, count, active);
            --active;
            lines[active].breakpoint = active + 1 < count
                ? intersection(lines[active], lines[active + 1]) : BREAKPOINT_INFINITY;
            cursor = active;
        } else cursor = active - 1;
        while (cursor > 0 && lines[cursor - 1].breakpoint >= lines[cursor].breakpoint) {
            erase_line(lines, count, cursor);
            --cursor;
            --active;
            lines[cursor].breakpoint = cursor + 1 < count
                ? intersection(lines[cursor], lines[cursor + 1]) : BREAKPOINT_INFINITY;
        }
    }
}

std::int64_t query(const Line *lines, std::size_t count,
                   std::int64_t x, std::int64_t objective) noexcept {
    std::size_t low = 0, high = count;
    while (low < high) {
        const auto middle = low + (high - low) / 2;
        if (lines[middle].breakpoint < x) low = middle + 1;
        else high = middle;
    }
    return (lines[low].slope * x + lines[low].intercept) * objective;
}
}

extern "C" std::int64_t arbitrary_order_line_container(const std::int64_t *input,
                                                        std::size_t length) noexcept {
    if (input == nullptr || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    const auto mode = input[0], operation_value = input[1];
    if ((mode != 0 && mode != 1) || operation_value < 0 || operation_value > static_cast<std::int64_t>(MAX_OPERATIONS)) return -1;
    const auto operations = static_cast<std::size_t>(operation_value);
    if (length != 2 + 3 * operations) return -1;
    bool seen_line = false;
    for (std::size_t operation = 0; operation < operations; ++operation) {
        const auto p = 2 + 3 * operation;
        const auto opcode = input[p], first = input[p + 1], second = input[p + 2];
        if (opcode == 0) {
            if (first < -1000 || first > 1000 || second < -1000 || second > 1000) return -1;
            seen_line = true;
        } else if (opcode == 1) {
            if (!seen_line || first < -1000 || first > 1000 || second != 0) return -1;
        } else return -1;
    }
    const std::int64_t objective = mode == 1 ? 1 : -1;
    Line lines[MAX_OPERATIONS]{};
    std::size_t line_count = 0, query_index = 0;
    std::int64_t checksum = 0;
    for (std::size_t operation = 0; operation < operations; ++operation) {
        const auto p = 2 + 3 * operation;
        if (input[p] == 0) insert_line(lines, line_count, input[p + 1] * objective, input[p + 2] * objective);
        else {
            const auto optimum = query(lines, line_count, input[p + 1], objective);
            checksum += static_cast<std::int64_t>(query_index + 1) * (optimum + CHECKSUM_OFFSET);
            ++query_index;
        }
    }
    return checksum;
}
