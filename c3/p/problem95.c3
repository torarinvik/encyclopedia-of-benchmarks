module problem95;

extern fn void* calloc(usz count, usz size);
extern fn void free(void* pointer);
const long MAX_LIMIT = 1000000;
const u32 MARK = 0x80000000;
const u32 VALUE_MASK = 0x7fffffff;

fn long problem95(long limit) @export("problem95") {
    if (limit < 1 || limit > MAX_LIMIT) return -1;
    u32* sums = (u32*)calloc((usz)limit + 1, sizeof(u32));
    if (sums == null) return -1;
    defer free(sums);
    for (long divisor = 1; divisor <= limit / 2; divisor++)
        for (long multiple = 2 * divisor; multiple <= limit; multiple += divisor)
            sums[multiple] += (u32)divisor;
    long best_length = 0, answer = 0;
    for (long start = 2; start <= limit; start++) {
        u32 current = sums[start];
        long length = 1;
        sums[start] |= MARK;
        while (current > 1 && current <= (u32)limit && (sums[current] & MARK) == 0) {
            sums[current] |= MARK;
            current = sums[current] & VALUE_MASK;
            length++;
        }
        if (current == (u32)start && length > best_length) { best_length = length; answer = start; }
        current = (u32)start;
        for (long step = 0; step < length; step++) {
            u32 next = sums[current] & VALUE_MASK;
            sums[current] = next;
            current = next;
        }
    }
    return answer;
}
