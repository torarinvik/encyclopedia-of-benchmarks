module shootout_hello;

const long SOURCE_CALLS = 1;
const usz OUTPUT_BYTES = 13;

fn long shootout_hello(long calls, char* output, usz output_capacity)
    @export("shootout_hello") {
    if (calls != SOURCE_CALLS) return -1;
    if (output == null || output_capacity < OUTPUT_BYTES) return -2;
    const char* source = "hello world\n\n";
    char[OUTPUT_BYTES] staged;
    for (usz index = 0; index < OUTPUT_BYTES; ++index) staged[index] = source[index];
    for (usz index = 0; index < OUTPUT_BYTES; ++index) output[index] = staged[index];
    return (long)OUTPUT_BYTES;
}
