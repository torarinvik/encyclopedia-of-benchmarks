module three_dimensional_bird_baker_matching;
const usz MAX_DIM = 5; const usz MAX_PAT_DIM = 4;
const usz MAX_INPUT = 196; const usz MAX_MATCHES = 125;

fn void put_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte += 1) {
        output[offset + byte] = (char)(bits & 255);
        bits >>= 8;
    }
}

fn bool same_rows(long* values, usz left, usz right, usz width) {
    for (usz column = 0; column < width; column += 1)
        if (values[left * width + column] != values[right * width + column]) return false;
    return true;
}

fn long three_dimensional_bird_baker_matching(long* input, usz length,
        char* output, usz capacity) @export("three_dimensional_bird_baker_matching") {
    if (input == null || length < 7 || length > MAX_INPUT) return -1;
    long r0 = input[0], c0 = input[1], d0 = input[2];
    long pr0 = input[3], pc0 = input[4], pd0 = input[5];
    if (r0 < 1 || r0 > 5 || c0 < 1 || c0 > 5 || d0 < 1 || d0 > 5
            || pr0 < 1 || pr0 > 4 || pc0 < 1 || pc0 > 4 || pd0 < 1 || pd0 > 4
            || pr0 > r0 || pc0 > c0 || pd0 > d0) return -1;
    usz rows = (usz)r0, columns = (usz)c0, depths = (usz)d0;
    usz p_rows = (usz)pr0, p_columns = (usz)pc0, p_depths = (usz)pd0;
    usz text_size = rows * columns * depths;
    usz pattern_size = p_rows * p_columns * p_depths;
    if (length != 6 + text_size + pattern_size) return -1;
    long[MAX_DIM * MAX_DIM * MAX_DIM] text = zeroed;
    long[MAX_PAT_DIM * MAX_PAT_DIM * MAX_PAT_DIM] pattern = zeroed;
    for (usz i = 0; i < text_size; i += 1) {
        text[i] = input[6 + i];
        if (text[i] < 0 || text[i] > 3) return -1;
    }
    for (usz i = 0; i < pattern_size; i += 1) {
        pattern[i] = input[6 + text_size + i];
        if (pattern[i] < 0 || pattern[i] > 3) return -1;
    }

    usz[MAX_PAT_DIM] plane_id = zeroed;
    long[MAX_PAT_DIM * MAX_PAT_DIM * MAX_PAT_DIM] unique_planes = zeroed;
    usz unique_count = 0, plane_area = p_rows * p_columns;
    for (usz pz = 0; pz < p_depths; pz += 1) {
        usz found = unique_count;
        for (usz candidate = 0; candidate < unique_count; candidate += 1) {
            bool equal = true;
            for (usz i = 0; i < plane_area; i += 1)
                if (unique_planes[candidate * MAX_PAT_DIM * MAX_PAT_DIM + i] != pattern[pz * plane_area + i]) equal = false;
            if (equal) { found = candidate; break; }
        }
        if (found == unique_count) {
            for (usz i = 0; i < plane_area; i += 1)
                unique_planes[unique_count * MAX_PAT_DIM * MAX_PAT_DIM + i] = pattern[pz * plane_area + i];
            unique_count += 1;
        }
        plane_id[pz] = found;
    }

    usz row_starts = rows - p_rows + 1, column_starts = columns - p_columns + 1;
    long[MAX_DIM * MAX_DIM * MAX_DIM] labels;
    for (usz i = 0; i < MAX_DIM * MAX_DIM * MAX_DIM; i += 1) labels[i] = -1;
    for (usz z = 0; z < depths; z += 1) {
        for (usz unique = 0; unique < unique_count; unique += 1) {
            bool[MAX_DIM * MAX_DIM * MAX_PAT_DIM] marks = zeroed;
            usz[MAX_PAT_DIM] prefix = zeroed;
            long* pplane = &unique_planes[unique * MAX_PAT_DIM * MAX_PAT_DIM];
            for (usz i = 1; i < p_rows; i += 1) {
                usz matched = prefix[i - 1];
                while (matched > 0 && !same_rows(pplane, i, matched, p_columns)) matched = prefix[matched - 1];
                if (same_rows(pplane, i, matched, p_columns)) matched += 1;
                prefix[i] = matched;
            }
            for (usz row = 0; row < rows; row += 1)
                for (usz column = 0; column < column_starts; column += 1)
                    for (usz pr = 0; pr < p_rows; pr += 1) {
                        bool equal = true;
                        for (usz pc = 0; pc < p_columns; pc += 1)
                            if (text[(z * rows + row) * columns + column + pc]
                                    != pplane[pr * p_columns + pc]) equal = false;
                        marks[(row * MAX_DIM + column) * MAX_PAT_DIM + pr] = equal;
                    }
            for (usz column = 0; column < column_starts; column += 1) {
                usz matched = 0;
                for (usz row = 0; row < rows; row += 1) {
                    while (matched > 0 && !marks[(row * MAX_DIM + column) * MAX_PAT_DIM + matched]) matched = prefix[matched - 1];
                    if (marks[(row * MAX_DIM + column) * MAX_PAT_DIM + matched]) matched += 1;
                    if (matched == p_rows) {
                        labels[(z * MAX_DIM + row + 1 - p_rows) * MAX_DIM + column] = (long)unique;
                        matched = prefix[matched - 1];
                    }
                }
            }
        }
    }

    usz[MAX_PAT_DIM] depth_prefix = zeroed;
    for (usz i = 1; i < p_depths; i += 1) {
        usz matched = depth_prefix[i - 1];
        while (matched > 0 && plane_id[i] != plane_id[matched]) matched = depth_prefix[matched - 1];
        if (plane_id[i] == plane_id[matched]) matched += 1;
        depth_prefix[i] = matched;
    }
    long[MAX_MATCHES * 3] positions = zeroed;
    usz count = 0;
    for (usz row = 0; row < row_starts; row += 1)
        for (usz column = 0; column < column_starts; column += 1) {
            usz matched = 0;
            for (usz z = 0; z < depths; z += 1) {
                long token = labels[(z * MAX_DIM + row) * MAX_DIM + column];
                while (matched > 0 && token != (long)plane_id[matched]) matched = depth_prefix[matched - 1];
                if (token == (long)plane_id[matched]) matched += 1;
                if (matched == p_depths) {
                    positions[count * 3] = (long)row;
                    positions[count * 3 + 1] = (long)column;
                    positions[count * 3 + 2] = (long)(z + 1 - p_depths);
                    count += 1;
                    matched = depth_prefix[matched - 1];
                }
            }
        }
    usz bytes = 8 * (1 + 3 * count);
    if (output == null || capacity < bytes) return -2;
    put_le(output, 0, (long)count);
    for (usz i = 0; i < count * 3; i += 1) put_le(output, 8 * (i + 1), positions[i]);
    return (long)bytes;
}
