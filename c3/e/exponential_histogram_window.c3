module exponential_histogram_window;

fn long exponential_histogram_window(long* input, usz length, char* output, usz capacity) @export("exponential_histogram_window") {
    if (input == null || length < 2 || length > 130 || input[0] < 1 || input[0] > 64 || input[1] < 0 || input[1] > 128) return -1;
    usz window = (usz)input[0], n = (usz)input[1];
    if (length != 2+n) return -1;
    for (usz i = 0; i < n; i++) if (input[2+i] != 0 && input[2+i] != 1) return -1;
    if (output == null || capacity < 8*n) return -2;
    usz[128] ends = {}, sizes = {};
    usz used = 0;
    for (usz time = 0; time < n; time++) {
        while (used != 0 && time >= window && ends[0] <= time-window) {
            for (usz j = 1; j < used; j++) { ends[j-1] = ends[j]; sizes[j-1] = sizes[j]; }
            used--;
        }
        if (input[2+time] == 1) { ends[used] = time; sizes[used] = 1; used++; }
        for (usz size = 1; size <= 128; size *= 2) {
            usz first = used, second = used, found = 0;
            for (usz j = 0; j < used; j++) if (sizes[j] == size) {
                if (found == 0) first = j;
                else if (found == 1) second = j;
                found++;
            }
            if (found > 2) {
                sizes[second] = 2*size;
                for (usz j = first+1; j < used; j++) { ends[j-1] = ends[j]; sizes[j-1] = sizes[j]; }
                used--;
            }
        }
        usz total = 0;
        for (usz j = 0; j < used; j++) total += sizes[j];
        ulong bits = (ulong)(2*total - (used != 0 ? sizes[0] : 0));
        for (usz j = 0; j < 8; j++) { output[8*time+j] = (char)(bits & 255); bits >>= 8; }
    }
    return (long)(8*n);
}
