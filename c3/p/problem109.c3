module problem109;

fn long problem109(long limit) @export("problem109") {
    long[63] values;
    long[21] doubles;
    usz value_count = 0, double_count = 0;
    for (long score = 1; score <= 20; score++) values[value_count++] = score;
    values[value_count++] = 25;
    for (long score = 1; score <= 20; score++) { doubles[double_count++] = 2 * score; values[value_count++] = 2 * score; }
    doubles[double_count++] = 50; values[value_count++] = 50;
    for (long score = 1; score <= 20; score++) values[value_count++] = 3 * score;
    values[value_count++] = 0;
    long count = 0;
    for (usz d = 0; d < double_count; d++)
        for (usz first = 0; first < value_count; first++)
            for (usz second = first; second < value_count; second++)
                if (doubles[d] + values[first] + values[second] < limit) count++;
    return count;
}
