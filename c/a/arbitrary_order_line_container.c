/* Arbitrary-order line envelope with integer intersection breakpoints. */
#include <stddef.h>
#include <stdint.h>

enum { MAX_OPERATIONS = 32, MAX_INPUT_LENGTH = 99 };
static const int64_t BREAKPOINT_INFINITY = INT64_C(1000000000000000);
static const int64_t CHECKSUM_OFFSET = INT64_C(2000001);

typedef struct {
    int64_t slope;
    int64_t intercept;
    int64_t breakpoint;
} Line;

static int64_t floor_div_positive_denominator(int64_t numerator, int64_t denominator)
{
    int64_t quotient = numerator / denominator;
    int64_t remainder = numerator % denominator;
    if (remainder != 0 && numerator < 0) --quotient;
    return quotient;
}

static int64_t intersection(Line left, Line right)
{
    return floor_div_positive_denominator(left.intercept - right.intercept,
                                          right.slope - left.slope);
}

static void erase_line(Line *lines, size_t *count, size_t position)
{
    for (size_t i = position; i + 1 < *count; ++i) lines[i] = lines[i + 1];
    --*count;
}

static void insert_line(Line *lines, size_t *count, int64_t slope, int64_t intercept)
{
    size_t position = 0;
    while (position < *count && lines[position].slope < slope) ++position;
    if (position < *count && lines[position].slope == slope) {
        if (lines[position].intercept >= intercept) return;
        erase_line(lines, count, position);
    }
    for (size_t i = *count; i > position; --i) lines[i] = lines[i - 1];
    lines[position] = (Line){ slope, intercept, BREAKPOINT_INFINITY };
    ++*count;

    size_t active = position;
    while (active + 1 < *count) {
        const int64_t breakpoint = intersection(lines[active], lines[active + 1]);
        lines[active].breakpoint = breakpoint;
        if (breakpoint >= lines[active + 1].breakpoint)
            erase_line(lines, count, active + 1);
        else
            break;
    }
    if (active + 1 == *count) lines[active].breakpoint = BREAKPOINT_INFINITY;

    if (active > 0) {
        const int64_t breakpoint = intersection(lines[active - 1], lines[active]);
        lines[active - 1].breakpoint = breakpoint;
        size_t cursor;
        if (breakpoint >= lines[active].breakpoint) {
            erase_line(lines, count, active);
            --active;
            if (active + 1 < *count)
                lines[active].breakpoint = intersection(lines[active], lines[active + 1]);
            else
                lines[active].breakpoint = BREAKPOINT_INFINITY;
            cursor = active;
        } else {
            cursor = active - 1;
        }
        while (cursor > 0 && lines[cursor - 1].breakpoint >= lines[cursor].breakpoint) {
            erase_line(lines, count, cursor);
            --cursor;
            --active;
            if (cursor + 1 < *count)
                lines[cursor].breakpoint = intersection(lines[cursor], lines[cursor + 1]);
            else
                lines[cursor].breakpoint = BREAKPOINT_INFINITY;
        }
    }
}

static int64_t query(const Line *lines, size_t count, int64_t x, int64_t objective)
{
    size_t low = 0, high = count;
    while (low < high) {
        const size_t middle = low + (high - low) / 2;
        if (lines[middle].breakpoint < x) low = middle + 1;
        else high = middle;
    }
    return (lines[low].slope * x + lines[low].intercept) * objective;
}

int64_t arbitrary_order_line_container(const int64_t *input, size_t length)
{
    if (input == NULL || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    const int64_t mode = input[0], operation_value = input[1];
    if ((mode != 0 && mode != 1) || operation_value < 0 || operation_value > MAX_OPERATIONS) return -1;
    const size_t operations = (size_t)operation_value;
    if (length != 2 + 3 * operations) return -1;

    int seen_line = 0;
    for (size_t operation = 0; operation < operations; ++operation) {
        const size_t p = 2 + 3 * operation;
        const int64_t opcode = input[p], first = input[p + 1], second = input[p + 2];
        if (opcode == 0) {
            if (first < -1000 || first > 1000 || second < -1000 || second > 1000) return -1;
            seen_line = 1;
        } else if (opcode == 1) {
            if (!seen_line || first < -1000 || first > 1000 || second != 0) return -1;
        } else return -1;
    }

    const int64_t objective = mode == 1 ? 1 : -1;
    Line lines[MAX_OPERATIONS];
    size_t line_count = 0, query_index = 0;
    int64_t checksum = 0;
    for (size_t operation = 0; operation < operations; ++operation) {
        const size_t p = 2 + 3 * operation;
        if (input[p] == 0) {
            insert_line(lines, &line_count, input[p + 1] * objective, input[p + 2] * objective);
        } else {
            const int64_t optimum = query(lines, line_count, input[p + 1], objective);
            checksum += (int64_t)(query_index + 1) * (optimum + CHECKSUM_OFFSET);
            ++query_index;
        }
    }
    return checksum;
}
