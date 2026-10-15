module fair_share_scheduling;

fn void store_i64_le(char* output, usz position, long value)
{
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) output[position + byte] = (char)((bits >> (byte * 8)) & 255);
}

fn long fair_share_scheduling(long* values, usz length, char* output, usz output_capacity)
    @export("fair_share_scheduling")
{
    if (values == null || length < 3 || length > 323 || values[0] < 0 || values[0] > 64 ||
        values[1] < 0 || values[1] > 128 || values[2] < 0 || values[2] > 1000000) return -2;
    usz user_count = (usz)values[0];
    usz task_count = (usz)values[1];
    long resources = values[2];
    if (length != 3 + user_count + 2 * task_count) return -2;

    long[64] ids;
    long[64] weights;
    usz[64] order;
    for (usz user = 0; user < user_count; user++) {
        long id = values[3 + user];
        if (id < 0 || id > 63) return -2;
        for (usz previous = 0; previous < user; previous++) {
            if (ids[previous] == id) return -2;
        }
        ids[user] = id;
        weights[user] = 0;
        order[user] = user;
    }
    usz task_start = 3 + user_count;
    for (usz task = 0; task < task_count; task++) {
        long owner = values[task_start + 2 * task];
        long weight = values[task_start + 2 * task + 1];
        if (owner < 0 || owner > 63 || weight < 0 || weight > 1000000) return -2;
        for (usz user = 0; user < user_count; user++) {
            if (ids[user] == owner) {
                weights[user] += weight;
                break;
            }
        }
    }
    for (usz i = 1; i < user_count; i++) {
        usz key = order[i];
        usz j = i;
        while (j > 0 && ids[order[j - 1]] > ids[key]) {
            order[j] = order[j - 1];
            j--;
        }
        order[j] = key;
    }
    long total_weight = 0;
    for (usz user = 0; user < user_count; user++) total_weight += weights[user];
    usz required = user_count * 24;
    if (output_capacity < required || (required != 0 && output == null)) return -2;
    for (usz position = 0; position < user_count; position++) {
        usz user = order[position];
        long allocation = total_weight == 0 ? 0 : weights[user] * resources / total_weight;
        store_i64_le(output, position * 24, ids[user]);
        store_i64_le(output, position * 24 + 8, weights[user]);
        store_i64_le(output, position * 24 + 16, allocation);
    }
    return (long)user_count;
}
