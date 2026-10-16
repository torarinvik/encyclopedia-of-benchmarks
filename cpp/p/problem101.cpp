#include <cstdint>

static std::int64_t question_function(std::int64_t n) noexcept
{
    std::int64_t term = 1, total = 0;
    for (int exponent = 0; exponent <= 10; ++exponent) {
        total += exponent % 2 == 0 ? term : -term;
        term *= n;
    }
    return total;
}

extern "C" std::int64_t problem101(std::int64_t order) noexcept
{
    if (order > 10) return -1;
    if (order <= 0) return 0;
    std::int64_t data[10];
    for (int i = 0; i < order; ++i) data[i] = question_function(i + 1);
    std::int64_t total_fit = 0;
    for (int k = 1; k <= order; ++k) {
        std::int64_t row[10]{}, differences[10]{};
        for (int i = 0; i < k; ++i) row[i] = data[i];
        differences[0] = row[0];
        for (int level = 1; level < k; ++level) {
            for (int i = 0; i < k - level; ++i) row[i] = row[i + 1] - row[i];
            differences[level] = row[0];
        }
        auto x = std::int64_t{1};
        std::int64_t prediction;
        for (;;) {
            prediction = 0;
            std::int64_t choose = 1;
            for (int j = 0; j < k; ++j) {
                prediction += differences[j] * choose;
                if (j + 1 < k) choose = choose * (x - 1 - j) / (j + 1);
            }
            if (prediction != question_function(x)) break;
            ++x;
        }
        total_fit += prediction;
    }
    return total_fit;
}
