module keith_number_checker;

extern fn void* malloc(usz size);
extern fn void free(void* memory);

// Preserve the digit-window recurrence used by the pinned C# checker.
fn long keith_number_checker(long number) @export("keith_number_checker")
{
    if (number < 2 || number > 1000) return -1;
    long original = number;
    long temp = number;
    long digits = 0;
    while (temp != 0) {
        digits++;
        temp /= 10;
    }

    long* terms = (long*)malloc((usz)number * 8);
    if (terms == null) return -1;
    for (usz i = 0; i < (usz)number; i++) terms[i] = 0;
    temp = number;
    for (long i = digits; i > 0; i--) {
        terms[(usz)(i - 1)] = temp % 10;
        temp /= 10;
    }

    long sum = 0;
    long k = digits;
    while (sum < original) {
        sum = 0;
        for (long j = 1; j <= digits; j++) sum += terms[(usz)(k - j)];
        terms[(usz)k] = sum;
        k++;
    }
    free(terms);
    return sum == original ? 1 : 0;
}
