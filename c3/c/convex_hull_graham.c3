module convex_hull_graham;

const usz MAX_POINTS = 64;

long cross(usz a, usz b, usz c, long* values) {
    long ax = values[2*a], ay = values[2*a+1];
    long bx = values[2*b], by = values[2*b+1];
    long cx = values[2*c], cy = values[2*c+1];
    return (bx-ax)*(cy-ay) - (by-ay)*(cx-ax);
}

int orientation(usz a, usz b, usz c, long* values) {
    long turn = cross(a, b, c, values);
    return turn < 0 ? 1 : turn > 0 ? -1 : 0;
}

bool before_x(usz left, usz right, long* values) {
    return values[2*left] < values[2*right];
}

void sort_indices(usz* items, usz* scratch, usz begin, usz end, long* values) {
    if (end - begin < 2) return;
    usz middle = begin + (end - begin) / 2;
    sort_indices(items, scratch, begin, middle, values);
    sort_indices(items, scratch, middle, end, values);
    usz left = begin, right = middle, out = begin;
    while (left < middle && right < end)
        scratch[out++] = before_x(items[right], items[left], values) ? items[right++] : items[left++];
    while (left < middle) scratch[out++] = items[left++];
    while (right < end) scratch[out++] = items[right++];
    for (usz index = begin; index < end; index++) items[index] = scratch[index];
}

void put_index(char* output, usz position, usz id) {
    u32 value = (u32)id;
    for (usz byte = 0; byte < 4; byte++) output[4*position+byte] = (char)(value >> (8*byte));
}

fn long convex_hull_graham(long* values, usz length, char* output, usz capacity)
    @export("convex_hull_graham") {
    if (values == null || length % 2 != 0 || length > 2*MAX_POINTS) return -1;
    usz count = length / 2;
    if (count < 3 || count > MAX_POINTS) return -1;
    for (usz index = 0; index < length; index++)
        if (values[index] < -2000 || values[index] > 2000) return -1;

    usz order[MAX_POINTS], scratch[MAX_POINTS], upper[MAX_POINTS], lower[MAX_POINTS];
    for (usz index = 0; index < count; index++) order[index] = index;
    sort_indices(&order[0], &scratch[0], 0, count, values);
    for (usz index = 1; index < count; index++)
        if (values[2*order[index-1]] == values[2*order[index]]) return -1;
    for (usz index = 1; index + 1 < count; index++)
        if (cross(order[0], order[index], order[count-1], values) == 0) return -1;

    usz upper_count = 1, lower_count = 1;
    upper[0] = 0; lower[0] = 0;
    for (usz index = 1; index < count; index++) {
        int turn = orientation(order[0], order[index], order[count-1], values);
        if (index == count-1 || turn != -1) {
            while (upper_count >= 2 && orientation(order[upper[upper_count-2]],
                order[upper[upper_count-1]], order[index], values) == -1) upper_count--;
            upper[upper_count++] = index;
        }
        if (index == count-1 || turn != 1) {
            while (lower_count >= 2 && orientation(order[lower[lower_count-2]],
                order[lower[lower_count-1]], order[index], values) == 1) lower_count--;
            lower[lower_count++] = index;
        }
    }
    usz hull_count = upper_count - 2 + lower_count;
    if (output == null || capacity < 4*hull_count) return -2;
    usz written = 0;
    for (usz index = 1; index + 1 < upper_count; index++) put_index(output, written++, order[upper[index]]);
    for (usz index = lower_count; index > 0; index--) put_index(output, written++, order[lower[index-1]]);
    return (long)hull_count;
}
