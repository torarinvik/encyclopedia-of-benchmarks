module proportional_fair_scheduling;

fn void store_i64_le(char* output, usz position, long value)
{
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) output[position + byte] = (char)((bits >> (byte * 8)) & 255);
}

fn long proportional_fair_scheduling(long* values, usz length, char* output,
                                      usz output_capacity)
    @export("proportional_fair_scheduling")
{
    if (values == null || length < 2 || length > 131) return -1;
    if (values[0] < 0 || values[0] > 64 || values[1] < 1 || values[1] > 1000000) return -1;
    usz process_count = (usz)values[0];
    long total_resources = values[1];
    if (length != 2 + 2 * process_count) return -1;

    long[64] name_ids;
    long[64] weights;
    long total_weight = 0;
    for (usz process = 0; process < process_count; process++) {
        long name_id = values[2 + 2 * process];
        long weight = values[3 + 2 * process];
        if (name_id < -2147483648 || name_id > 2147483647 || weight < 1 || weight > 1000000) return -1;
        name_ids[process] = name_id;
        weights[process] = weight;
        total_weight += weight;
    }

    if (process_count == 0) return 0;
    usz required = process_count * 16;
    if (output == null || output_capacity < required) return -2;
    for (usz process = 0; process < process_count; process++) {
        double quotient = (double)weights[process] / (double)total_weight;
        double share = quotient * (double)total_resources;
        int allocation = (int)share;
        store_i64_le(output, process * 16, name_ids[process]);
        store_i64_le(output, process * 16 + 8, (long)allocation);
    }
    return (long)required;
}
