module hanging_line_largest_rectangle;

const usz MAX_LENGTH = 64;
const long MAX_HEIGHT = 1000000;
const long INVALID_RESULT = -9223372036854775807 - 1;

fn long hanging_line_largest_rectangle(long* heights, usz length)
    @export("hanging_line_largest_rectangle") {
    if (length == 0) return 0;
    if (heights == null || length > MAX_LENGTH) return INVALID_RESULT;
    for (usz i = 0; i < length; i++) {
        if (heights[i] < 0 || heights[i] > MAX_HEIGHT) return INVALID_RESULT;
    }

    usz[MAX_LENGTH] left = {};
    usz[MAX_LENGTH] right = {};
    for (usz i = 0; i < length; i++) {
        left[i] = i;
        while (left[i] > 0 && heights[i] <= heights[left[i] - 1])
            left[i] = left[left[i] - 1];
    }
    usz i = length;
    while (i > 0) {
        i--;
        right[i] = i;
        while (right[i] + 1 < length && heights[i] <= heights[right[i] + 1])
            right[i] = right[right[i] + 1];
    }

    long best = 0;
    for (usz j = 0; j < length; j++) {
        long width = (long)(right[j] - left[j] + 1);
        long area = heights[j] * width;
        if (area > best) best = area;
    }
    return best;
}
