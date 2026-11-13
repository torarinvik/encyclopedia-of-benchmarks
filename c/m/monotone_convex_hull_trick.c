#include <stddef.h>
#include <stdint.h>

enum { MAX_LINES = 32, MAX_QUERIES = 32, MAX_LENGTH = 99 };
typedef struct { int64_t slope, intercept; } Line;

static int64_t value(Line line, int64_t x) { return line.slope * x + line.intercept; }

static int redundant(Line a, Line b, Line c)
{
    return (b.intercept - a.intercept) * (b.slope - c.slope)
        >= (c.intercept - b.intercept) * (a.slope - b.slope);
}

int64_t monotone_convex_hull_trick(const int64_t *values, size_t length)
{
    const int64_t invalid = INT64_MIN;
    if (values == NULL || length < 2 || length > MAX_LENGTH) return invalid;
    int64_t line_count_value = values[0], query_count_value = values[1];
    if (line_count_value < 1 || line_count_value > MAX_LINES
        || query_count_value < 0 || query_count_value > MAX_QUERIES) return invalid;
    size_t line_count = (size_t)line_count_value;
    size_t query_count = (size_t)query_count_value;
    if (length != 2 + 2 * line_count + query_count) return invalid;

    Line hull[MAX_LINES];
    size_t hull_count = 0;
    int64_t previous_slope = INT64_MAX;
    size_t cursor = 2;
    for (size_t i = 0; i < line_count; ++i) {
        Line line = { values[cursor], values[cursor + 1] };
        cursor += 2;
        if (line.slope < -1000 || line.slope > 1000
            || line.intercept < -10000 || line.intercept > 10000
            || line.slope >= previous_slope) return invalid;
        previous_slope = line.slope;
        while (hull_count >= 2 && redundant(hull[hull_count - 2], hull[hull_count - 1], line))
            --hull_count;
        hull[hull_count++] = line;
    }

    size_t front = 0;
    int64_t checksum = 0;
    int64_t previous_x = INT64_MIN;
    for (size_t i = 0; i < query_count; ++i) {
        int64_t x = values[cursor + i];
        if (x < -1000 || x > 1000 || (i != 0 && x < previous_x)) return invalid;
        previous_x = x;
        while (front + 1 < hull_count && value(hull[front + 1], x) <= value(hull[front], x)) ++front;
        checksum += (int64_t)(i + 1) * value(hull[front], x);
    }
    return checksum;
}
