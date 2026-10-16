module cpu_scheduling_algorithms;

fn void put_i64_le(long value, char* output, usz offset) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte += 1) { output[offset + byte] = (char)(bits & 255); bits >>= 8; }
}

fn bool better_choice(long mode, usz candidate, usz best, long* arrival,
                      long* burst, long* remaining, long* priority) {
    if (mode == 1) return burst[candidate] < burst[best]
        || (burst[candidate] == burst[best] && (arrival[candidate] < arrival[best]
        || (arrival[candidate] == arrival[best] && candidate < best)));
    if (mode == 2) return remaining[candidate] < remaining[best]
        || (remaining[candidate] == remaining[best] && (arrival[candidate] < arrival[best]
        || (arrival[candidate] == arrival[best] && candidate < best)));
    return priority[candidate] < priority[best]
        || (priority[candidate] == priority[best] && candidate < best);
}

fn long cpu_scheduling_algorithms(long* input, usz length, char* output, usz capacity)
    @export("cpu_scheduling_algorithms") {
    if (input == null || length < 3 || length > 3 + 4*32) return -1;
    long mode = input[0];
    long raw_count = input[1];
    long quantum = input[2];
    if (mode < 0 || mode > 5 || raw_count < 0 || raw_count > 32 || quantum < 1 || quantum > 32) return -1;
    usz count = (usz)raw_count;
    if (length != 3 + 4*count) return -1;

    long[32] ids, arrival, burst, priority, remaining, completion, first_run;
    usz[32] order;
    for (usz i = 0; i < count; i += 1) {
        usz base = 3 + 4*i;
        ids[i] = input[base]; arrival[i] = input[base+1];
        burst[i] = input[base+2]; priority[i] = input[base+3];
        if (ids[i] < 0 || ids[i] >= 32 || arrival[i] < 0 || arrival[i] > 256
            || burst[i] < 1 || burst[i] > 32 || priority[i] < -32 || priority[i] > 32) return -1;
        for (usz j = 0; j < i; j += 1) if (ids[j] == ids[i]) return -1;
        remaining[i] = burst[i]; completion[i] = -1; first_run[i] = -1; order[i] = i;
    }
    usz bytes = count*56;
    if (bytes > 0 && (output == null || capacity < bytes)) return -2;

    if (mode == 0 || mode == 5) {
        for (usz i = 1; i < count; i += 1) {
            usz key = order[i];
            usz j = i;
            while (j > 0 && arrival[order[j-1]] > arrival[key]) { order[j] = order[j-1]; j -= 1; }
            order[j] = key;
        }
    }

    long time = 0;
    if (mode == 0) {
        for (usz position = 0; position < count; position += 1) {
            usz i = order[position];
            if (time < arrival[i]) time = arrival[i];
            first_run[i] = time; time += burst[i]; completion[i] = time;
        }
    } else if (mode == 1 || mode == 3) {
        usz done = 0;
        while (done < count) {
            usz best = count;
            for (usz i = 0; i < count; i += 1) {
                if (completion[i] >= 0 || arrival[i] > time) continue;
                if (best == count || better_choice(mode, i, best, &arrival[0], &burst[0], &remaining[0], &priority[0])) best = i;
            }
            if (best == count) { time += 1; continue; }
            first_run[best] = time; time += burst[best]; completion[best] = time; done += 1;
        }
    } else if (mode == 2 || mode == 4) {
        usz done = 0;
        while (done < count) {
            usz best = count;
            for (usz i = 0; i < count; i += 1) {
                if (remaining[i] <= 0 || arrival[i] > time) continue;
                if (best == count || better_choice(mode, i, best, &arrival[0], &burst[0], &remaining[0], &priority[0])) best = i;
            }
            if (best == count) { time += 1; continue; }
            if (first_run[best] < 0) first_run[best] = time;
            remaining[best] -= 1; time += 1;
            if (remaining[best] == 0) { completion[best] = time; done += 1; }
        }
    } else {
        usz[64] queue;
        usz head = 0;
        usz tail = 0;
        usz queue_size = 0;
        usz next_arrival = 0;
        usz done = 0;
        while (done < count) {
            while (next_arrival < count && arrival[order[next_arrival]] <= time) {
                queue[tail] = order[next_arrival]; next_arrival += 1; tail = (tail+1)%64; queue_size += 1;
            }
            if (queue_size == 0) { time += 1; continue; }
            usz current = queue[head]; head = (head+1)%64; queue_size -= 1;
            long run_for = quantum < remaining[current] ? quantum : remaining[current];
            for (long slot = 0; slot < run_for; slot += 1) {
                if (first_run[current] < 0) first_run[current] = time;
                remaining[current] -= 1; time += 1;
                while (next_arrival < count && arrival[order[next_arrival]] <= time) {
                    queue[tail] = order[next_arrival]; next_arrival += 1; tail = (tail+1)%64; queue_size += 1;
                }
            }
            if (remaining[current] > 0) { queue[tail] = current; tail = (tail+1)%64; queue_size += 1; }
            else { completion[current] = time; done += 1; }
        }
    }

    for (usz i = 0; i < count; i += 1) {
        long turnaround = completion[i] - arrival[i];
        long[7] fields = {ids[i], arrival[i], burst[i], completion[i], turnaround,
                          turnaround-burst[i], first_run[i]-arrival[i]};
        for (usz field = 0; field < 7; field += 1) put_i64_le(fields[field], output, i*56+field*8);
    }
    return (long)bytes;
}
