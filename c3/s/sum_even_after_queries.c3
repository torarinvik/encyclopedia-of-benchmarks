module sum_even_after_queries;

const long MAX_NUMBERS = 1000;
const long MAX_QUERIES = 1000;

fn long sum_even_after_queries(long* values, usz length, char* output, usz output_capacity) @export("sum_even_after_queries") {
    if (length < 5 || length > 4002 || values == null) return -1;
    if (values[0] < 1 || values[0] > MAX_NUMBERS || values[1] < 1 || values[1] > MAX_QUERIES) return -1;
    usz number_count = (usz)values[0];
    usz query_count = (usz)values[1];
    if (length != 2 + number_count + 2 * query_count) return -1;

    long[1000] working;
    long even_sum = 0;
    for (usz index = 0; index < number_count; index++) {
        long value = values[2 + index];
        if (value < 1 || value > 1000) return -1;
        working[index] = value;
        if (value % 2 == 0) even_sum += value;
    }
    for (usz query = 0; query < query_count; query++) {
        usz offset = 2 + number_count + 2 * query;
        if (values[offset] < -1000 || values[offset] > 1000 ||
            values[offset + 1] < 0 || values[offset + 1] >= (long)number_count) return -1;
    }
    usz output_bytes = query_count * 4;
    if (output_capacity < output_bytes || output == null) return -2;

    for (usz query = 0; query < query_count; query++) {
        usz offset = 2 + number_count + 2 * query;
        long delta = values[offset];
        usz index = (usz)values[offset + 1];
        if (working[index] % 2 == 0) even_sum -= working[index];
        working[index] += delta;
        if (working[index] % 2 == 0) even_sum += working[index];
        ulong bits = (ulong)even_sum;
        for (usz byte = 0; byte < 4; byte++) {
            output[query * 4 + byte] = (char)((bits >> (byte * 8)) & 255);
        }
    }
    return (long)query_count;
}
