module lossy_counting_summary;

fn void put_word(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz j = 0; j < 8; j++) { output[offset+j] = (char)(bits & 255); bits >>= 8; }
}

fn long lossy_counting_summary(long* input, usz length, char* output, usz capacity) @export("lossy_counting_summary") {
    if (input == null || length < 2 || length > 66 || input[0] < 2 || input[0] > 16 || input[1] < 0 || input[1] > 64) return -1;
    usz width = (usz)input[0], n = (usz)input[1];
    if (length != 2+n) return -1;
    for (usz i = 0; i < n; i++) if (input[2+i] < 0 || input[2+i] > 15) return -1;
    long[16] count = {}, error = {};
    for (usz i = 0; i < n; i++) {
        usz item = (usz)input[2+i];
        long bucket = (long)(i/width+1);
        if (count[item] == 0) error[item] = bucket-1;
        count[item]++;
        if ((i+1)%width == 0) {
            for (usz j = 0; j < 16; j++) {
                if (count[j] != 0 && count[j]+error[j] <= bucket) { count[j] = 0; error[j] = 0; }
            }
        }
    }
    usz active = 0;
    for (usz i = 0; i < 16; i++) if (count[i] != 0) active++;
    usz bytes = 8+24*active;
    if (output == null || capacity < bytes) return -2;
    put_word(output, 0, (long)active);
    usz offset = 8;
    for (usz i = 0; i < 16; i++) if (count[i] != 0) {
        put_word(output, offset, (long)i);
        put_word(output, offset+8, count[i]);
        put_word(output, offset+16, error[i]);
        offset += 24;
    }
    return (long)bytes;
}
