module bandwidth_allocation;

const long MAX_USERS = 64;

fn long bandwidth_allocation(long* input, usz length) @export("bandwidth_allocation") {
    if (input == null || length < 2) return -1;
    long bandwidth = input[0];
    long count_value = input[1];
    if (bandwidth < 0 || bandwidth > 100000 || count_value < 0 || count_value > MAX_USERS) return -1;
    usz count = (usz)count_value;
    if (length != 2 + 2 * count) return -1;
    for (usz index = 0; index < count; index++) {
        long demand = input[2 + index];
        long value = input[2 + count + index];
        if (demand < 1 || demand > 1000 || value < 0 || value > 10000) return -1;
    }

    double[64] ratios;
    long[64] order;
    for (usz index = 0; index < count; index++) {
        long demand = input[2 + index];
        long value = input[2 + count + index];
        ratios[index] = (double)value / (double)demand;
        order[index] = (long)index;
    }
    for (usz index = 1; index < count; index++) {
        double key_ratio = ratios[index];
        long key_index = order[index];
        usz position = index;
        while (position > 0 && ratios[position - 1] < key_ratio) {
            ratios[position] = ratios[position - 1];
            order[position] = order[position - 1];
            position--;
        }
        ratios[position] = key_ratio;
        order[position] = key_index;
    }

    long remaining = bandwidth;
    long total = 0;
    for (usz position = 0; position < count; position++) {
        usz index = (usz)order[position];
        long demand = input[2 + index];
        long value = input[2 + count + index];
        if (remaining >= demand) {
            total += value;
            remaining -= demand;
        } else {
            total += (long)(ratios[position] * (double)remaining);
            break;
        }
    }
    return total;
}
