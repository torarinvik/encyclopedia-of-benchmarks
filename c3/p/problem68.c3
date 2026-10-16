module problem68;

fn bool next_permutation(long* indices, int length) {
    int pivot = length - 2;
    while (pivot >= 0 && indices[pivot] >= indices[pivot + 1]) pivot--;
    if (pivot < 0) return false;
    int successor = length - 1;
    while (indices[successor] <= indices[pivot]) successor--;
    long temporary = indices[pivot];
    indices[pivot] = indices[successor];
    indices[successor] = temporary;
    int left = pivot + 1;
    int right = length - 1;
    while (left < right) {
        temporary = indices[left]; indices[left] = indices[right]; indices[right] = temporary;
        left++; right--;
    }
    return true;
}

fn long value_at(long* values, long* indices, int position) {
    return values[indices[position]];
}

fn long problem68(long gon_side) @export("problem68") {
    if (gon_side < 3 || gon_side > 5) return -1;
    int n = (int)gon_side;
    int length = 2 * n;
    long[10] values;
    int cursor = 0;
    for (int value = n + 1; value >= 1; value--) values[cursor++] = value;
    for (int value = n + 2; value <= 2 * n; value++) values[cursor++] = value;
    long[10] indices;
    for (int i = 0; i < length; i++) indices[i] = i;
    while (true) {
        long total = value_at(&values[0], &indices[0], 0) + value_at(&values[0], &indices[0], 1) + value_at(&values[0], &indices[0], 2);
        bool magic = true;
        long minimum_outer = value_at(&values[0], &indices[0], 0);
        for (int line = 1; line < n; line++) {
            int outer = line == n - 1 ? 2 * n - 1 : 2 * line + 1;
            int inner_left = 2 * line;
            int inner_right = line == n - 1 ? 1 : 2 * line + 2;
            long external = value_at(&values[0], &indices[0], outer);
            if (external + value_at(&values[0], &indices[0], inner_left) + value_at(&values[0], &indices[0], inner_right) != total) magic = false;
            if (external < minimum_outer) minimum_outer = external;
        }
        if (magic && value_at(&values[0], &indices[0], 0) == minimum_outer) {
            long result = 0;
            for (int line = 0; line < n; line++) {
                int outer = line == 0 ? 0 : (line == n - 1 ? 2 * n - 1 : 2 * line + 1);
                int inner_left = line == 0 ? 1 : 2 * line;
                int inner_right = line == n - 1 ? 1 : (line == 0 ? 2 : 2 * line + 2);
                long triple[3] = {value_at(&values[0], &indices[0], outer), value_at(&values[0], &indices[0], inner_left), value_at(&values[0], &indices[0], inner_right)};
                for (int part = 0; part < 3; part++) result = result * (triple[(usz)part] >= 10 ? 100 : 10) + triple[(usz)part];
            }
            return result;
        }
        if (!next_permutation(&indices[0], length)) break;
    }
    return -1;
}
