module sparse_supernodal_cholesky;

extern fn double sqrt(double value);

fn long sparse_supernodal_cholesky(long* input, usz length, char* output, usz capacity)
    @export("sparse_supernodal_cholesky") {
    if (input == null || length < 2 || length > 56) return -1;
    if (input[0] < 1 || input[0] > 8 || input[1] < 1 || input[1] > input[0]) return -1;
    usz n = (usz)input[0], count = (usz)input[1];
    usz triangle = n * (n + 1) / 2;
    if (length != 3 + count + n + triangle) return -1;
    usz[9] boundary = zeroed;
    usz[8] masks = zeroed;
    usz[64] slots = zeroed;
    for (usz i = 0; i <= count; i++) {
        if (input[2 + i] < 0 || input[2 + i] > (long)n) return -1;
        boundary[i] = (usz)input[2 + i];
        if (i > 0 && boundary[i] <= boundary[i - 1]) return -1;
    }
    if (boundary[0] != 0 || boundary[count] != n) return -1;
    for (usz row = 0; row < n; row++) {
        long mask = input[3 + count + row];
        if (mask < 0 || mask >= ((long)1 << (row + 1)) || (mask & ((long)1 << row)) == 0) return -1;
        masks[row] = (usz)mask;
        for (usz col = 0; col < n; col++) slots[row * 8 + col] = 36;
    }
    for (usz col = 0; col < n; col++) {
        for (usz row = col + 1; row < n; row++) {
            if ((masks[row] & ((usz)1 << col)) == 0) continue;
            for (usz lower = row + 1; lower < n; lower++) {
                if ((masks[lower] & ((usz)1 << col)) != 0 && (masks[lower] & ((usz)1 << row)) == 0) return -1;
            }
        }
    }
    for (usz block = 0; block < count; block++) {
        usz start = boundary[block], end = boundary[block + 1];
        for (usz row = start; row < end; row++) {
            for (usz col = start; col < row; col++) {
                if ((masks[row] & ((usz)1 << col)) == 0) return -1;
            }
        }
        usz bits = (((usz)1 << end) - 1) ^ (((usz)1 << start) - 1);
        for (usz row = end; row < n; row++) {
            usz selected = masks[row] & bits;
            if (selected != 0 && selected != bits) return -1;
        }
    }
    double[36] sparse = zeroed;
    usz cursor = 3 + count + n, used = 0;
    for (usz row = 0; row < n; row++) {
        for (usz col = 0; col <= row; col++) {
            long value = input[cursor++];
            if (value < -1000000 || value > 1000000) return -1;
            if ((masks[row] & ((usz)1 << col)) == 0) {
                if (value != 0) return -1;
            } else {
                slots[row * 8 + col] = used;
                sparse[used++] = (double)value / 1000.0;
            }
        }
    }
    for (usz block = 0; block < count; block++) {
        usz start = boundary[block], end = boundary[block + 1];
        for (usz col = start; col < end; col++) {
            double pivot = sparse[slots[col * 8 + col]];
            ulong exponent = @bitcast(ulong, pivot) & 0x7ff0000000000000;
            if (exponent == 0x7ff0000000000000 || pivot <= 0.0) return -1;
            sparse[slots[col * 8 + col]] = sqrt(pivot);
            for (usz row = col + 1; row < end; row++)
                sparse[slots[row * 8 + col]] /= sparse[slots[col * 8 + col]];
            for (usz row = col + 1; row < end; row++) {
                for (usz target = col + 1; target <= row; target++)
                    sparse[slots[row * 8 + target]] -= sparse[slots[row * 8 + col]] * sparse[slots[target * 8 + col]];
            }
        }
        for (usz row = end; row < n; row++) {
            if ((masks[row] & ((usz)1 << start)) == 0) continue;
            for (usz col = start; col < end; col++) {
                double value = sparse[slots[row * 8 + col]];
                for (usz k = start; k < col; k++) value -= sparse[slots[row * 8 + k]] * sparse[slots[col * 8 + k]];
                sparse[slots[row * 8 + col]] = value / sparse[slots[col * 8 + col]];
            }
        }
        for (usz row = end; row < n; row++) {
            if ((masks[row] & ((usz)1 << start)) == 0) continue;
            for (usz target = end; target <= row; target++) {
                if ((masks[target] & ((usz)1 << start)) == 0) continue;
                for (usz k = start; k < end; k++)
                    sparse[slots[row * 8 + target]] -= sparse[slots[row * 8 + k]] * sparse[slots[target * 8 + k]];
            }
        }
    }
    usz required = triangle * 8;
    if (output == null || capacity < required) return -2;
    usz offset = 0;
    for (usz row = 0; row < n; row++) {
        for (usz col = 0; col <= row; col++) {
            usz slot = slots[row * 8 + col];
            double value = slot == 36 ? 0.0 : sparse[slot];
            ulong bits = @bitcast(ulong, value);
            for (usz byte = 0; byte < 8; byte++) {
                output[offset++] = (char)(bits & 255);
                bits >>= 8;
            }
        }
    }
    return (long)required;
}
