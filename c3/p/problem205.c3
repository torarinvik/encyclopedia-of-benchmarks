module problem205;

const long MAX_TOTAL = 36;
const long SCALE = 10000000;

fn void distribution(long sides, long dice, long* output) {
    long[37] current = {0}, next = {0};
    current[0] = 1;
    for (long die = 0; die < dice; die++) {
        for (long total = 0; total <= MAX_TOTAL; total++) next[total] = 0;
        for (long total = 0; total <= MAX_TOTAL; total++) if (current[total] != 0)
            for (long face = 1; face <= sides; face++) next[total + face] += current[total];
        for (long total = 0; total <= MAX_TOTAL; total++) current[total] = next[total];
    }
    for (long total = 0; total <= MAX_TOTAL; total++) output[total] = current[total];
}

fn long problem205(long placeholder) @export("problem205") {
    if (placeholder != 0) return -1;
    long[37] peter = {0}, colin = {0};
    distribution(4, 9, &peter[0]);
    distribution(6, 6, &colin[0]);
    long wins = 0, colin_below = 0;
    for (long total = 0; total <= MAX_TOTAL; total++) {
        if (total >= 9) wins += peter[total] * colin_below;
        colin_below += colin[total];
    }
    long games = (long)262144 * 46656;
    long scaled = wins * SCALE;
    long rounded = scaled / games;
    long remainder = scaled % games;
    if (2 * remainder > games || (2 * remainder == games && rounded % 2 != 0)) rounded++;
    return rounded;
}
