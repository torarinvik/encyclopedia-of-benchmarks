module naive_shuffler;

const usz MAX_ITEMS = 256;
const long RNG_MODULUS = 2147483647;
const long RNG_PERIOD = 2147483646;

fn long naive_shuffler(long* input, usz length, char* output, usz output_capacity)
    @export("naive_shuffler")
{
    if (input == null || length < 2 || length > MAX_ITEMS + 2) return -1;
    if (input[0] < 0 || input[0] >= RNG_PERIOD || input[1] < 0 || input[1] > (long)MAX_ITEMS) return -1;
    usz count = (usz)input[1];
    if (length != count + 2) return -1;

    char[MAX_ITEMS] items;
    for (usz index = 0; index < count; index++) {
        if (input[index + 2] < 0 || input[index + 2] > 255) return -1;
        items[index] = (char)input[index + 2];
    }
    if (output_capacity < count || (count > 0 && output == null)) return -2;

    long state = input[0] + 1;
    for (usz index = 0; index < count; index++) {
        long bound = (long)count;
        long limit = RNG_PERIOD - RNG_PERIOD % bound;
        long sample;
        while (true) {
            state = (state * 48271) % RNG_MODULUS;
            sample = state - 1;
            if (sample < limit) break;
        }
        usz other = (usz)(sample % bound);
        char temporary = items[index];
        items[index] = items[other];
        items[other] = temporary;
    }
    for (usz index = 0; index < count; index++) output[index] = items[index];
    return (long)count;
}
