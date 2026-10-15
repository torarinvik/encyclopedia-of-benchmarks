module next_greater_nodes;

const usz MAX_NODE_COUNT = 4096;

fn long next_greater_nodes(long* values, usz length, char* output, usz output_capacity)
        @export("next_greater_nodes") {
    if (length == 0 || length > MAX_NODE_COUNT || values == null) return -1;
    for (usz index = 0; index < length; index++) {
        if (values[index] < 1 || values[index] > 1000000000) return -1;
    }
    if (output_capacity < 4 * length || output == null) return -2;
    for (usz index = 0; index < length; index++) {
        long next_greater = 0;
        for (usz later = index + 1; later < length; later++) {
            if (values[later] > values[index]) {
                next_greater = values[later];
                break;
            }
        }
        uint encoded = (uint)next_greater;
        output[4 * index] = (char)(encoded & 0xff);
        output[4 * index + 1] = (char)((encoded >> 8) & 0xff);
        output[4 * index + 2] = (char)((encoded >> 16) & 0xff);
        output[4 * index + 3] = (char)((encoded >> 24) & 0xff);
    }
    return (long)length;
}
