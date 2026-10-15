module golombs_sequence;

fn long golombs_sequence(long index) @export("golombs_sequence") {
    if (index < 0 || index > 64) return -1;
    if (index == 0) return 1;
    if (index <= 2) return 2;
    long[65] queue;
    for (usz i = 0; i < 65; i++) queue[i] = 0;
    queue[0] = 2;
    usz head = 0;
    usz tail = 1;
    long generated = 3;
    for (long value = 3; generated <= index; value += 1) {
        long repetitions = queue[head];
        head += 1;
        for (long j = 0; j < repetitions && generated <= index; j += 1) {
            queue[tail] = value;
            tail += 1;
            if (generated == index) return value;
            generated += 1;
        }
    }
    return -1;
}
