#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t MAX_OPERATIONS = 256;
constexpr std::int64_t DIMENSION_LIMIT = 1000;
constexpr std::int64_t RESULT_OFFSET = 1000000007;

std::int64_t integer_sqrt(std::int64_t value)
{
    std::int64_t low = 0, high = 3037000499LL, answer = 0;
    while (low <= high) {
        const std::int64_t middle = low + (high - low) / 2;
        if (middle == 0 || middle <= value / middle) {
            answer = middle;
            low = middle + 1;
        } else high = middle - 1;
    }
    return answer;
}

std::int64_t scale_pi(std::int64_t value)
{
    return value * 3 + value * 141592654LL / 1000000000LL;
}

std::int64_t scale_pi_squared(std::int64_t value)
{
    return value * 9 + value * 869604401LL / 1000000000LL;
}

std::int64_t regular_polygon_coefficient(std::int64_t sides)
{
    switch (sides) {
    case 3: return 433012701LL; case 4: return 1000000000LL;
    case 5: return 1720477400LL; case 6: return 2598076211LL;
    case 7: return 3633912444LL; case 8: return 4828427124LL;
    case 9: return 6181824193LL; case 10: return 7694208842LL;
    case 11: return 9365639906LL; case 12: return 11196152422LL;
    case 13: return 13185768328LL; case 14: return 15334501936LL;
    case 15: return 17642362910LL; case 16: return 20109357968LL;
    case 17: return 22735491898LL; case 18: return 25520768188LL;
    case 19: return 28465189427LL; case 20: return 31568757573LL;
    case 21: return 34831474123LL; case 22: return 38253340244LL;
    case 23: return 41834356852LL; case 24: return 45574524676LL;
    case 25: return 49473844301LL; case 26: return 53532316204LL;
    case 27: return 57749940771LL; case 28: return 62126718324LL;
    case 29: return 66662649129LL; case 30: return 71357733406LL;
    case 31: return 76211971344LL; case 32: return 81225363100LL;
    default: return -1;
    }
}

std::int64_t area_milli(std::int64_t operation, std::int64_t a,
                        std::int64_t b, std::int64_t c)
{
    switch (operation) {
    case 0: return a * a * 1000;
    case 1: return a * b * 1000;
    case 2: return a * b * 500;
    case 3: return scale_pi(a * a * 1000);
    case 4: return a * b * 1000;
    case 5: return (a + b) * c * 500;
    case 6: {
        const std::int64_t perimeter = a + b + c;
        if (a + b < c || a + c < b || b + c < a) return -1;
        const std::int64_t radicand = perimeter * (perimeter - 2 * a)
                                    * (perimeter - 2 * b) * (perimeter - 2 * c);
        return integer_sqrt(radicand * 1000000LL) / 4;
    }
    case 7: return scale_pi(a * b * 1000);
    case 8: return a * b * 500;
    case 9: return 6 * a * a * 1000;
    case 10: return 2 * (a * b + a * c + b * c) * 1000;
    case 11: return scale_pi(4 * a * a * 1000);
    case 12: return scale_pi(3 * a * a * 1000);
    case 13: return scale_pi(2 * a * (b + a) * 1000);
    case 14: return scale_pi(2 * a * b * 1000);
    case 15: {
        const std::int64_t slant_milli = integer_sqrt((a * a + b * b) * 1000000LL);
        return scale_pi(a * a * 1000 + a * slant_milli);
    }
    case 16: {
        const std::int64_t slant_milli = integer_sqrt((a * a + b * b) * 1000000LL);
        return scale_pi(a * slant_milli);
    }
    case 17: return (a * a + 2 * a * b) * 1000;
    case 18: {
        const std::int64_t difference = a >= b ? a - b : b - a;
        const std::int64_t slant_milli = integer_sqrt((c * c + difference * difference) * 1000000LL);
        return scale_pi((a * a + b * b) * 1000 + (a + b) * slant_milli);
    }
    case 19: return scale_pi_squared(4 * a * b * 1000);
    case 20: {
        const std::int64_t coefficient = regular_polygon_coefficient(a);
        return coefficient < 0 ? -1 : coefficient * b * b / 1000000LL;
    }
    case 21: {
        const std::int64_t coefficient = regular_polygon_coefficient(a);
        if (coefficient < 0) return -1;
        const std::int64_t base_area = coefficient * b * b / 1000000LL;
        return 2 * base_area + a * b * c * 1000;
    }
    default: return -1;
    }
}
}

extern "C" std::int64_t area_benchmark(const std::int64_t *values, std::size_t length)
{
    if (length < 1 || length > 1025) return -1;
    const std::int64_t count_value = values[0];
    if (count_value < 0 || count_value > MAX_OPERATIONS
        || length != 1 + 4 * static_cast<std::size_t>(count_value)) return -1;
    std::int64_t checksum = 0;
    for (std::size_t index = 0; index < static_cast<std::size_t>(count_value); ++index) {
        const std::size_t position = 1 + 4 * index;
        const std::int64_t operation = values[position];
        const std::int64_t a = values[position + 1], b = values[position + 2], c = values[position + 3];
        if (operation < 0 || operation > 21 || a < 0 || a > DIMENSION_LIMIT
            || b < 0 || b > DIMENSION_LIMIT || c < 0 || c > DIMENSION_LIMIT) return -1;
        if ((operation == 0 || operation == 3 || operation == 9 || operation == 11
             || operation == 12) && (b != 0 || c != 0)) return -1;
        if ((operation == 1 || operation == 2 || operation == 4 || operation == 7
             || operation == 8 || (operation >= 13 && operation <= 17)
             || operation == 19 || operation == 20) && c != 0) return -1;
        const std::int64_t result = area_milli(operation, a, b, c);
        if (result < 0) return -1;
        checksum += static_cast<std::int64_t>(index + 1) * (result + RESULT_OFFSET);
    }
    return checksum;
}
