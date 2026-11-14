module space_saving_frequent_items;

long space_saving_frequent_items(long* input, usz length, char* output, usz capacity)
        @export("space_saving_frequent_items") {
    if (input == null || length < 2 || length > 67) return -1;
    if (input[0] < 1 || input[0] > 8 || input[1] < 0 || input[1] > 64) return -1;
    usz k = input[0].usz(), n = input[1].usz();
    if (length != 2+n) return -1;
    for (usz i = 0; i < n; i += 1) {
        if (input[2+i] < -1000 || input[2+i] > 1000) return -1;
    }
    long[8] items = zeroed, estimates = zeroed, errors = zeroed;
    usz used = 0;
    for (usz i = 0; i < n; i += 1) {
        long item = input[2+i];
        usz found = used;
        for (usz j = 0; j < used; j += 1) {
            if (items[j] == item) { found = j; break; }
        }
        if (found < used) estimates[found] += 1;
        else if (used < k) {
            items[used] = item; estimates[used] = 1; errors[used] = 0; used += 1;
        } else {
            usz victim = 0;
            for (usz j = 1; j < used; j += 1) {
                if (estimates[j] < estimates[victim] ||
                    (estimates[j] == estimates[victim] && items[j] < items[victim])) victim = j;
            }
            long minimum = estimates[victim];
            items[victim] = item; estimates[victim] = minimum+1; errors[victim] = minimum;
        }
    }
    for (usz i = 1; i < used; i += 1) {
        usz j = i;
        while (j > 0 && items[j] < items[j-1]) {
            long item = items[j], estimate = estimates[j], error = errors[j];
            items[j] = items[j-1]; estimates[j] = estimates[j-1]; errors[j] = errors[j-1];
            items[j-1] = item; estimates[j-1] = estimate; errors[j-1] = error;
            j -= 1;
        }
    }
    usz bytes = 8*(1+3*used);
    if (output == null || capacity < bytes) return -2;
    long[25] fields = zeroed;
    fields[0] = used.long();
    for (usz i = 0; i < used; i += 1) {
        fields[1+3*i] = items[i]; fields[2+3*i] = estimates[i]; fields[3+3*i] = errors[i];
    }
    char[200] staged = zeroed;
    for (usz i = 0; i < 1+3*used; i += 1) {
        ulong bits = (ulong)fields[i];
        for (usz b = 0; b < 8; b += 1) { staged[8*i+b] = (char)(bits & 255); bits >>= 8; }
    }
    for (usz i = 0; i < bytes; i += 1) output[i] = staged[i];
    return bytes.long();
}
