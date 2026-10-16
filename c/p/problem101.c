#include <stdint.h>

static int64_t question_function(int64_t n)
{
    int64_t term = 1, total = 0;
    for (int exponent = 0; exponent <= 10; ++exponent) {
        total += exponent % 2 == 0 ? term : -term;
        term *= n;
    }
    return total;
}

int64_t problem101(int64_t order)
{
    if (order > 10) return -1;
    if (order <= 0) return 0;
    int64_t data[10];
    for (int i = 0; i < order; ++i) data[i] = question_function(i + 1);
    int64_t total_fit = 0;
    for (int k = 1; k <= order; ++k) {
        int64_t row[10] = {0}, differences[10] = {0};
        for (int i = 0; i < k; ++i) row[i] = data[i];
        differences[0] = row[0];
        for (int level = 1; level < k; ++level) {
            for (int i = 0; i < k - level; ++i) row[i] = row[i + 1] - row[i];
            differences[level] = row[0];
        }
        int64_t x = 1, prediction;
        do {
            prediction = 0;
            int64_t choose = 1;
            for (int j = 0; j < k; ++j) {
                prediction += differences[j] * choose;
                if (j + 1 < k) choose = choose * (x - 1 - j) / (j + 1);
            }
            if (prediction == question_function(x)) ++x;
            else break;
        } while (1);
        total_fit += prediction;
    }
    return total_fit;
}
