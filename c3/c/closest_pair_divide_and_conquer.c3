module closest_pair_divide_and_conquer;

const MAX_POINTS = 1024;

fn bool before(usz left, usz right, long* points, bool by_y) {
    if (by_y) {
        if (points[2 * left + 1] != points[2 * right + 1]) return points[2 * left + 1] < points[2 * right + 1];
        if (points[2 * left] != points[2 * right]) return points[2 * left] < points[2 * right];
    } else {
        if (points[2 * left] != points[2 * right]) return points[2 * left] < points[2 * right];
        if (points[2 * left + 1] != points[2 * right + 1]) return points[2 * left + 1] < points[2 * right + 1];
    }
    return left < right;
}

fn void sort_indices(usz* indices, usz* scratch, usz begin, usz end, long* points, bool by_y) {
    if (end - begin < 2) return;
    usz middle = begin + (end - begin) / 2;
    sort_indices(indices, scratch, begin, middle, points, by_y);
    sort_indices(indices, scratch, middle, end, points, by_y);
    usz left = begin, right = middle, out = begin;
    while (left < middle && right < end) {
        if (before(indices[right], indices[left], points, by_y)) scratch[out++] = indices[right++];
        else scratch[out++] = indices[left++];
    }
    while (left < middle) scratch[out++] = indices[left++];
    while (right < end) scratch[out++] = indices[right++];
    for (usz index = begin; index < end; index++) indices[index] = scratch[index];
}

fn long squared_distance(usz left, usz right, long* points) {
    long dx = points[2 * left] - points[2 * right];
    long dy = points[2 * left + 1] - points[2 * right + 1];
    return dx * dx + dy * dy;
}

fn void choose_pair(long* left, long* right, long* result) {
    if (left[0] == 0) {
        for (usz index = 0; index < 4; index++) result[index] = right[index];
        return;
    }
    if (right[0] == 0) {
        for (usz index = 0; index < 4; index++) result[index] = left[index];
        return;
    }
    bool take_left = left[1] < right[1] ||
        (left[1] == right[1] && (left[2] < right[2] || (left[2] == right[2] && left[3] <= right[3])));
    if (take_left) {
        for (usz index = 0; index < 4; index++) result[index] = left[index];
    } else {
        for (usz index = 0; index < 4; index++) result[index] = right[index];
    }
}

fn void make_candidate(usz left, usz right, long* points, long* result) {
    if (left > right) {
        usz temporary = left;
        left = right;
        right = temporary;
    }
    result[0] = 1;
    result[1] = squared_distance(left, right, points);
    result[2] = (long)left;
    result[3] = (long)right;
}

fn void search(usz* x_order, usz begin, usz end, usz* y_order, usz y_count,
               usz* rank, long* points, long* result) {
    usz count = end - begin;
    if (count <= 3) {
        result[0] = 0; result[1] = 0; result[2] = 0; result[3] = 0;
        for (usz i = begin; i < end; i++) {
            for (usz j = i + 1; j < end; j++) {
                long[4] current;
                long[4] chosen;
                make_candidate(x_order[i], x_order[j], points, &current[0]);
                choose_pair(&result[0], &current[0], &chosen[0]);
                for (usz k = 0; k < 4; k++) result[k] = chosen[k];
            }
        }
        return;
    }

    usz middle = begin + count / 2;
    usz[MAX_POINTS] y_left, y_right;
    usz left_count = 0, right_count = 0;
    for (usz i = 0; i < y_count; i++) {
        usz point = y_order[i];
        if (rank[point] < middle) y_left[left_count++] = point;
        else y_right[right_count++] = point;
    }

    long[4] left_result, right_result;
    long[4] best;
    search(x_order, begin, middle, &y_left[0], left_count, rank, points, &left_result[0]);
    search(x_order, middle, end, &y_right[0], right_count, rank, points, &right_result[0]);
    choose_pair(&left_result[0], &right_result[0], &best[0]);

    usz[MAX_POINTS] strip;
    usz strip_count = 0;
    long middle_x = points[2 * x_order[middle]];
    for (usz i = 0; i < y_count; i++) {
        usz point = y_order[i];
        long dx = points[2 * point] - middle_x;
        if (dx * dx <= best[1]) strip[strip_count++] = point;
    }
    for (usz i = 0; i < strip_count; i++) {
        for (usz j = i + 1; j < strip_count; j++) {
            long dy = points[2 * strip[j] + 1] - points[2 * strip[i] + 1];
            if (dy * dy > best[1]) break;
            long[4] current, chosen;
            make_candidate(strip[i], strip[j], points, &current[0]);
            choose_pair(&best[0], &current[0], &chosen[0]);
            for (usz k = 0; k < 4; k++) best[k] = chosen[k];
        }
    }
    for (usz k = 0; k < 4; k++) result[k] = best[k];
}

fn long closest_pair_divide_and_conquer(long* values, usz length, char* output, usz output_capacity)
    @export("closest_pair_divide_and_conquer")
{
    if (length > 2 * MAX_POINTS || length % 2 != 0 || (length != 0 && values == null)) return -1;
    usz point_count = length / 2;

    usz[MAX_POINTS] x_order, y_order, rank, scratch;
    for (usz i = 0; i < point_count; i++) {
        long x = values[2 * i], y = values[2 * i + 1];
        if (x < -1000000000L || x > 1000000000L || y < -1000000000L || y > 1000000000L) return -1;
        x_order[i] = i;
        y_order[i] = i;
    }
    if (point_count < 2) return 0;
    sort_indices(&x_order[0], &scratch[0], 0, point_count, values, false);
    for (usz i = 0; i < point_count; i++) rank[x_order[i]] = i;

    long[4] duplicate = {0, 0, 0, 0};
    for (usz begin = 0; begin < point_count;) {
        usz end = begin + 1;
        usz anchor = x_order[begin];
        while (end < point_count && values[2 * x_order[end]] == values[2 * anchor] &&
               values[2 * x_order[end] + 1] == values[2 * anchor + 1]) end++;
        if (end - begin > 1) {
            usz first = MAX_POINTS, second = MAX_POINTS;
            for (usz i = begin; i < end; i++) {
                usz id = x_order[i];
                if (id < first) { second = first; first = id; }
                else if (id < second) second = id;
            }
            long[4] current = {1, 0, (long)first, (long)second};
            long[4] chosen;
            choose_pair(&duplicate[0], &current[0], &chosen[0]);
            for (usz k = 0; k < 4; k++) duplicate[k] = chosen[k];
        }
        begin = end;
    }
    long[4] best;
    if (duplicate[0] != 0) {
        for (usz k = 0; k < 4; k++) best[k] = duplicate[k];
    } else {
        sort_indices(&y_order[0], &scratch[0], 0, point_count, values, true);
        search(&x_order[0], 0, point_count, &y_order[0], point_count, &rank[0], values, &best[0]);
    }
    if (best[0] == 0) return -1;
    if (output == null || output_capacity < 8) return -2;
    for (usz byte = 0; byte < 4; byte++) {
        output[byte] = (char)(((uint)best[2] >> (byte * 8)) & 255);
        output[4 + byte] = (char)(((uint)best[3] >> (byte * 8)) & 255);
    }
    return 2;
}
