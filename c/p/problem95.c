#include <stdint.h>
#include <stdlib.h>

#define MAX_LIMIT 1000000
#define MARK UINT32_C(0x80000000)
#define VALUE_MASK UINT32_C(0x7fffffff)

int64_t problem95(int64_t limit)
{
    if (limit < 1 || limit > MAX_LIMIT) return -1;
    uint32_t *sums = (uint32_t *)calloc((size_t)limit + 1, sizeof(uint32_t));
    if (sums == NULL) return -1;
    for (int64_t divisor = 1; divisor <= limit / 2; ++divisor)
        for (int64_t multiple = 2 * divisor; multiple <= limit; multiple += divisor)
            sums[multiple] += (uint32_t)divisor;
    int64_t best_length = 0, answer = 0;
    for (int64_t start = 2; start <= limit; ++start) {
        uint32_t current = sums[start];
        int64_t length = 1;
        sums[start] |= MARK;
        while (current > 1 && current <= (uint64_t)limit && (sums[current] & MARK) == 0) {
            sums[current] |= MARK;
            current = sums[current] & VALUE_MASK;
            ++length;
        }
        if (current == (uint32_t)start && length > best_length) { best_length = length; answer = start; }
        current = (uint32_t)start;
        for (int64_t step = 0; step < length; ++step) {
            uint32_t next = sums[current] & VALUE_MASK;
            sums[current] = next;
            current = next;
        }
    }
    free(sums);
    return answer;
}
