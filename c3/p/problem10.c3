module problem10;

extern fn void* calloc(usz count, usz size);
extern fn void free(void* ptr);

fn long problem10(long limit) @export("problem10") {
    if (limit < 0 || limit > 2000000) return -1;
    char* composite = calloc(1000000, 1);
    if (composite == null) return -1;
    long odd_count = limit / 2;
    long sum = limit > 2 ? 2 : 0;
    for (long prime = 3; prime * prime < limit; prime += 2) {
        if (composite[prime / 2] == 0) {
            for (long index = prime * prime / 2; index < odd_count; index += prime) {
                composite[index] = 1;
            }
        }
    }
    for (long index = 1; index < odd_count; index++) {
        if (composite[index] == 0) sum += 2 * index + 1;
    }
    free(composite);
    return sum;
}
