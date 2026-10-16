module problem69;

extern fn void* malloc(usz size);
extern fn void free(void* pointer);
const long MAX_LIMIT = 1000000;

fn long problem69(long inclusive_limit) @export("problem69") {
    if (inclusive_limit < 1 || inclusive_limit > MAX_LIMIT) return -1;
    usz limit = (usz)inclusive_limit;
    u32* phi = (u32*)malloc((limit + 1) * sizeof(u32));
    if (phi == null) return -1;
    defer free(phi);
    for (usz value = 0; value <= limit; ++value) phi[value] = (u32)value;
    for (usz number = 2; number <= limit; ++number) {
        if (phi[number] != (u32)number) continue;
        phi[number]--;
        for (usz multiple = number * 2; multiple <= limit; multiple += number) {
            phi[multiple] = (phi[multiple] / (u32)number) * (u32)(number - 1);
        }
    }
    usz answer = 1;
    for (usz number = 1; number <= limit; ++number) {
        if ((ulong)number * (ulong)phi[answer] > (ulong)answer * (ulong)phi[number]) answer = number;
    }
    return (long)answer;
}
