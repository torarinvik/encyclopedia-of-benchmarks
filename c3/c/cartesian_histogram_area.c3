// Uncompiled and unexecuted Cartesian-tree histogram draft.
module cartesian_histogram_area;
fn long cartesian_histogram_area(long* heights, usz length) @export("cartesian_histogram_area") {
    long invalid = long.min;
    if (length == 0) return 0;
    if (heights == null || length > 64) return invalid;
    for (usz i = 0; i < length; i++) if (heights[i] < 0 || heights[i] > 1000000) return invalid;
    usz[64] left = {}, right = {}, stack = {}, order = {}, sizes = {};
    for (usz i = 0; i < length; i++) { left[i] = length; right[i] = length; }
    usz top = 0;
    for (usz i = 0; i < length; i++) {
        usz last = length;
        while (top > 0 && heights[stack[top-1]] > heights[i]) { top--; last = stack[top]; }
        if (top > 0) right[stack[top-1]] = i;
        left[i] = last; stack[top] = i; top++;
    }
    usz root = stack[0], used = 0;
    top = 0; stack[top++] = root;
    while (top > 0) {
        top--; usz node = stack[top]; order[used++] = node;
        if (left[node] < length) stack[top++] = left[node];
        if (right[node] < length) stack[top++] = right[node];
    }
    long best = 0;
    while (used > 0) {
        used--; usz node = order[used];
        sizes[node] = 1+(left[node] < length ? sizes[left[node]] : 0)
                       +(right[node] < length ? sizes[right[node]] : 0);
        long area = heights[node]*(long)sizes[node];
        if (area > best) best = area;
    }
    return best;
}
