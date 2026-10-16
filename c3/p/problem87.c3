module problem87;

extern fn void* calloc(usz count, usz size);
extern fn void free(void* pointer);
const long MAX_LIMIT = 50000000;
fn long integer_sqrt(long value) { long root = 0; while ((root + 1) * (root + 1) <= value) root++; return root; }

fn long problem87(long limit) @export("problem87") {
    if (limit < 24 || limit > MAX_LIMIT) return -1;
    long root = integer_sqrt(limit - 24);
    long bound = root < 2 ? 2 : root;
    u8[7072] prime = {0};
    for (long p = 2; p <= bound; p++) prime[p] = 1;
    for (long p = 2; p * p <= bound; p++) if (prime[p])
        for (long multiple = p * p; multiple <= bound; multiple += p) prime[multiple] = 0;
    usz bytes = (usz)((limit + 7) / 8);
    u8* seen = (u8*)calloc(bytes, sizeof(u8));
    if (seen == null) return -1;
    defer free(seen);
    for (long p1 = 2; p1 <= bound; p1++) if (prime[p1]) {
        long square = p1 * p1;
        for (long p2 = 2; p2 <= bound; p2++) if (prime[p2]) {
            long cube = p2 * p2 * p2;
            if (square + cube >= limit - 16) break;
            for (long p3 = 2; p3 <= bound; p3++) if (prime[p3]) {
                long total = square + cube + p3 * p3 * p3 * p3;
                if (total >= limit) break;
                usz index = (usz)total;
                seen[index / 8] |= (u8)(1 << (total % 8));
            }
        }
    }
    long count = 0;
    for (usz i = 0; i < bytes; i++) { u8 bits = seen[i]; while (bits != 0) { count++; bits &= bits - 1; } }
    return count;
}
