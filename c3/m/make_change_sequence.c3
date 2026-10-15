module make_change_sequence;

fn long make_change_sequence(long amount) @export("make_change_sequence") {
    if (amount < 0 || amount > 128) return -1;
    long[129] values;
    values[0] = 1; values[1] = 1; values[2] = 2; values[3] = 2; values[4] = 3;
    values[5] = 4; values[6] = 5; values[7] = 6; values[8] = 7; values[9] = 8;
    values[10] = 11; values[11] = 12; values[12] = 15; values[13] = 16;
    values[14] = 19; values[15] = 22; values[16] = 25;
    for (long n = 17; n <= amount; n += 1) {
        values[(usz)n] = values[(usz)(n - 2)] + values[(usz)(n - 5)] - values[(usz)(n - 7)]
                       + values[(usz)(n - 10)] - values[(usz)(n - 12)] - values[(usz)(n - 15)]
                       + values[(usz)(n - 17)] + 1;
    }
    return values[(usz)amount];
}
