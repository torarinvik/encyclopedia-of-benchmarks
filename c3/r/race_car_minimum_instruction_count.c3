module race_car_minimum_instruction_count;

fn long race_car_minimum_instruction_count(long* input, usz length)
        @export("race_car_minimum_instruction_count") {
    if (input == null || length < 1 || length > 2 || length != 1) return -1;
    long target_value = input[0];
    if (target_value < 0 || target_value > 127) return -1;
    usz target = (usz)target_value;
    int[128] distance = zeroed;

    for (usz position = 1; position <= target; position++) {
        usz run = 0;
        usz upper_power = 1;
        while (upper_power <= position) {
            upper_power *= 2;
            run++;
        }
        usz upper = upper_power - 1;
        if (position == upper) {
            distance[position] = (int)run;
            continue;
        }

        int best = (int)(run + 1) + distance[upper - position];
        usz lower = upper_power / 2 - 1;
        for (usz backward_run = 0; backward_run + 1 < run; backward_run++) {
            usz backward_distance = ((usz)1 << backward_run) - 1;
            usz remaining = position - (lower - backward_distance);
            int candidate = (int)(run + backward_run + 1) + distance[remaining];
            if (candidate < best) best = candidate;
        }
        distance[position] = best;
    }
    return (long)distance[target];
}
