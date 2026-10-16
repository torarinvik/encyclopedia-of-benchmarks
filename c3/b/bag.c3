module bag;

const long MAX_INSERTS = 128;
const long MAX_QUERIES = 64;

fn void put_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) output[offset + byte] = (char)(bits >> (byte * 8));
}

fn long bag_impl(long* input, usz length, char* output, usz capacity) {
    if (input == null || length < 2) return -1;
    long insert_count_value = input[0];
    if (insert_count_value < 0 || insert_count_value > MAX_INSERTS) return -1;
    usz insert_count = (usz)insert_count_value;
    if (length < insert_count + 2) return -1;
    long query_count_value = input[insert_count + 1];
    if (query_count_value < 0 || query_count_value > MAX_QUERIES) return -1;
    usz query_count = (usz)query_count_value;
    if (length != insert_count + query_count + 2) return -1;

    for (usz index = 0; index < insert_count; index++) {
        long value = input[index + 1];
        if (value < -2147483648 || value > 2147483647) return -1;
    }
    for (usz query = 0; query < query_count; query++) {
        long value = input[insert_count + query + 2];
        if (value < -2147483648 || value > 2147483647) return -1;
    }
    usz output_length = (query_count + 2) * 8;
    if (output == null || capacity < output_length) return -2;

    long[128] values;
    usz distinct_count = 0;
    for (usz index = 0; index < insert_count; index++) {
        long value = input[index + 1];
        usz node = 0;
        while (node < distinct_count && values[node] != value) node++;
        if (node == distinct_count) {
            values[node] = value;
            distinct_count++;
        }
    }

    put_i64_le(output, 0, insert_count_value);
    put_i64_le(output, 8, insert_count_value == 0 ? 1 : 0);
    for (usz query = 0; query < query_count; query++) {
        long target = input[insert_count + query + 2];
        long contains = 0;
        for (usz node = 0; node < distinct_count; node++) {
            if (values[node] == target) { contains = 1; break; }
        }
        put_i64_le(output, (query + 2) * 8, contains);
    }
    return (long)output_length;
}

fn long bag(long* input, usz length, char* output, usz capacity) @export("bag") {
    return bag_impl(input, length, output, capacity);
}
