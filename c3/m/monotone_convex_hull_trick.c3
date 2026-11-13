module monotone_convex_hull_trick;

const usz MAX_LINES = 32;
const usz MAX_QUERIES = 32;
const usz MAX_LENGTH = 99;
const long INVALID = -9223372036854775807L - 1;

struct Line { long slope; long intercept; }

fn long line_value(Line line, long x) { return line.slope * x + line.intercept; }

fn bool redundant(Line a, Line b, Line c) {
    return (b.intercept - a.intercept) * (b.slope - c.slope)
        >= (c.intercept - b.intercept) * (a.slope - b.slope);
}

fn long monotone_convex_hull_trick(long* values, usz length) @export("monotone_convex_hull_trick") {
    if (values == null || length < 2 || length > MAX_LENGTH) return INVALID;
    if (values[0] < 1 || values[0] > (long)MAX_LINES
        || values[1] < 0 || values[1] > (long)MAX_QUERIES) return INVALID;
    usz line_count = (usz)values[0];
    usz query_count = (usz)values[1];
    if (length != 2 + 2 * line_count + query_count) return INVALID;

    Line[MAX_LINES] hull = {};
    usz hull_count = 0;
    long previous_slope = 9223372036854775807L;
    usz cursor = 2;
    for (usz i = 0; i < line_count; i++) {
        Line line = { values[cursor], values[cursor + 1] };
        cursor += 2;
        if (line.slope < -1000 || line.slope > 1000 || line.intercept < -10000
            || line.intercept > 10000 || line.slope >= previous_slope) return INVALID;
        previous_slope = line.slope;
        while (hull_count >= 2 && redundant(hull[hull_count - 2], hull[hull_count - 1], line)) hull_count--;
        hull[hull_count] = line;
        hull_count++;
    }

    usz front = 0;
    long previous_x = INVALID;
    long checksum = 0;
    for (usz i = 0; i < query_count; i++) {
        long x = values[cursor + i];
        if (x < -1000 || x > 1000 || (i > 0 && x < previous_x)) return INVALID;
        previous_x = x;
        while (front + 1 < hull_count && line_value(hull[front + 1], x) <= line_value(hull[front], x)) front++;
        checksum += (long)(i + 1) * line_value(hull[front], x);
    }
    return checksum;
}
