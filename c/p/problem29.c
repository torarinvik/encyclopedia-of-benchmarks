/* Count distinct exact powers a^b for 2 <= a,b <= limit. */
#include <stdint.h>

int64_t problem29(int64_t limit)
{
    if (limit < 1 || limit > 100) return -1;
    if (limit == 1) return 0;

    int64_t roots[101] = {0};
    int64_t exponents[101] = {0};
    unsigned char seen[60701] = {0};
    int64_t distinct = 0;
    for (int64_t a = 2; a <= limit; ++a) {
        roots[a] = a;
        exponents[a] = 1;
        for (int64_t candidate_exponent = 2; candidate_exponent <= 6; ++candidate_exponent) {
            for (int64_t candidate_root = 2; candidate_root <= a; ++candidate_root) {
                int64_t power = 1;
                for (int64_t step = 0; step < candidate_exponent; ++step) {
                    power *= candidate_root;
                    if (power > a) break;
                }
                if (power == a && candidate_exponent > exponents[a]) {
                    roots[a] = candidate_root;
                    exponents[a] = candidate_exponent;
                }
            }
        }
        for (int64_t b = 2; b <= limit; ++b) {
            const int64_t key = roots[a] * 601 + exponents[a] * b;
            if (!seen[key]) { seen[key] = 1; ++distinct; }
        }
    }
    return distinct;
}
