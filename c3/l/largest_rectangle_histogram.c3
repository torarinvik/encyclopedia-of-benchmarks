module largest_rectangle_histogram;

const usz MAX_INPUT_LENGTH = 64;
const long INVALID_RESULT = -9223372036854775807 - 1;

fn long largest_rectangle_histogram(long* heights, usz length) @export("largest_rectangle_histogram") {
    if (length == 0) return 0;
    if (heights == null || length > MAX_INPUT_LENGTH) return INVALID_RESULT;
    for (usz index = 0; index < length; index++) {
        if (heights[index] < 0 || heights[index] > 1000000) return INVALID_RESULT;
    }

    usz[64] stack = {0};
    usz top = 0;
    long best = 0;
    for (usz index = 0; index < length; index++) {
        while (top > 0 && heights[stack[top - 1]] > heights[index]) {
            usz bar = stack[top - 1];
            top--;
            usz left = top == 0 ? 0 : stack[top - 1] + 1;
            long area = heights[bar] * (long)(index - left);
            best = best > area ? best : area;
        }
        stack[top] = index;
        top++;
    }
    while (top > 0) {
        usz bar = stack[top - 1];
        top--;
        usz left = top == 0 ? 0 : stack[top - 1] + 1;
        long area = heights[bar] * (long)(length - left);
        best = best > area ? best : area;
    }
    return best;
}
