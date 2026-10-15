module fcfs_scheduling;

fn void store_i64_le(char* output, usz position, long value)
{
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) {
        output[position + byte] = (char)((bits >> (byte * 8)) & 255);
    }
}

fn long fcfs_scheduling(long* values, usz length, char* output, usz output_capacity)
    @export("fcfs_scheduling")
{
    if (values == null || length < 1 || length > 193 || values[0] < 0 || values[0] > 64) return -2;
    usz count = (usz)values[0];
    if (length != 1 + 3 * count) return -2;

    long[64] ids;
    long[64] arrivals;
    long[64] bursts;
    usz[64] order;
    for (usz i = 0; i < count; i++) {
        long id = values[1 + 3 * i];
        long arrival = values[2 + 3 * i];
        long burst = values[3 + 3 * i];
        if (id < 0 || id > 63 || arrival < 0 || arrival > 1000000 || burst < 1 || burst > 1000000) {
            return -2;
        }
        for (usz previous = 0; previous < i; previous++) {
            if (ids[previous] == id) return -2;
        }
        ids[i] = id;
        arrivals[i] = arrival;
        bursts[i] = burst;
        order[i] = i;
    }
    for (usz i = 1; i < count; i++) {
        usz key = order[i];
        usz j = i;
        while (j > 0 && (arrivals[order[j - 1]] > arrivals[key] ||
                (arrivals[order[j - 1]] == arrivals[key] && ids[order[j - 1]] > ids[key]))) {
            order[j] = order[j - 1];
            j--;
        }
        order[j] = key;
    }

    usz required = count * 48;
    if (output_capacity < required || (required != 0 && output == null)) return -2;
    long elapsed = 0;
    for (usz position = 0; position < count; position++) {
        usz i = order[position];
        if (elapsed < arrivals[i]) elapsed = arrivals[i];
        long completion = elapsed + bursts[i];
        long turnaround = completion - arrivals[i];
        long waiting = turnaround - bursts[i];
        long[6] fields = {ids[i], arrivals[i], bursts[i], completion, turnaround, waiting};
        for (usz field = 0; field < 6; field++) {
            store_i64_le(output, position * 48 + field * 8, fields[field]);
        }
        elapsed = completion;
    }
    return (long)count;
}
