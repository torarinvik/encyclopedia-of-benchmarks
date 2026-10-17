// Count sol2's bounded, source-ordered digit-factorial chains.
module problem74_sol2;

extern fn void* calloc(usz count, usz size);
extern fn void free(void* pointer);

const long MAX_CHAIN_LENGTH = 60;
const long MAX_NUMBER_LIMIT = 1000000;
const usz PATH_CAPACITY = 61;
const long[10] DIGIT_FACTORIALS = {1, 1, 2, 6, 24, 120, 720, 5040, 40320, 362880};

fn long digit_factorial_sum(long value) {
    long total = 0;
    do {
        total += DIGIT_FACTORIALS[(usz)(value % 10)];
        value /= 10;
    } while (value > 0);
    return total;
}

fn bool cache_contains(long value, long number_limit, u32* cache) {
    return value >= 1 && value < number_limit && cache[(usz)value] != 0;
}

fn bool path_contains(long* path, usz path_length, long value) {
    for (usz index = 0; index < path_length; index++)
        if (path[index] == value) return true;
    return false;
}

fn long problem74_sol2(long chain_length, long number_limit) @export("problem74_sol2") {
    if (chain_length < 1 || chain_length > MAX_CHAIN_LENGTH ||
        number_limit < 1 || number_limit > MAX_NUMBER_LIMIT) return -1;
    if (number_limit == 1) return 0;

    u32* cache = (u32*)calloc((usz)number_limit, sizeof(u32));
    if (cache == null) return -1;
    defer free(cache);

    long chains_counter = 0;
    for (long start = 1; start < number_limit; start++) {
        long[PATH_CAPACITY] path = {0};
        usz path_length = 0;
        long chain_set_length = 0;
        long chain_element = start;
        while (!cache_contains(chain_element, number_limit, cache) &&
               !path_contains(&path[0], path_length, chain_element) &&
               chain_set_length <= chain_length) {
            path[path_length++] = chain_element;
            chain_set_length++;
            chain_element = digit_factorial_sum(chain_element);
        }
        if (cache_contains(chain_element, number_limit, cache))
            chain_set_length += (long)cache[(usz)chain_element];

        cache[(usz)start] = (u32)chain_set_length;
        if (chain_set_length == chain_length) chains_counter++;
    }
    return chains_counter;
}
