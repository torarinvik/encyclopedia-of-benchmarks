#include <cstdint>

static bool is_squarefree(std::int64_t number) noexcept
{
    auto copy = number;
    for (std::int64_t divisor = 2; divisor * divisor <= copy; ++divisor) {
        int multiplicity = 0;
        while (copy % divisor == 0) { copy /= divisor; ++multiplicity; }
        if (multiplicity >= 2) return false;
    }
    return true;
}

extern "C" std::int64_t problem203(std::int64_t depth) noexcept
{
    if (depth > 51) return -1;
    std::int64_t row[51]{1};
    std::int64_t values[1326];
    int count = 1, row_length = 1;
    values[0] = 1;
    for (std::int64_t row_index = 2; row_index <= depth; ++row_index) {
        row[row_length] = 1;
        for (int col = row_length - 1; col > 0; --col) row[col] += row[col - 1];
        row[0] = 1;
        ++row_length;
        for (int col = 0; col < row_length; ++col) values[count++] = row[col];
    }
    for (int i = 1; i < count; ++i) {
        const auto value = values[i];
        int j = i;
        while (j > 0 && values[j - 1] > value) { values[j] = values[j - 1]; --j; }
        values[j] = value;
    }
    std::int64_t total = 0;
    for (int i = 0; i < count; ++i) {
        if (i > 0 && values[i] == values[i - 1]) continue;
        if (is_squarefree(values[i])) total += values[i];
    }
    return total;
}
