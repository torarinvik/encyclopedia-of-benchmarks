// Independent hook-length count; see package README.
#include <cstddef>
#include <cstdint>

static constexpr int64_t hook_prime = 998244353;

extern "C" int64_t hook_length_tableaux(const int64_t *input, std::size_t length) {
    if (!input || length == 0 || input[0] < 0 || input[0] > 65536) return -1;
    const auto rows = static_cast<std::size_t>(input[0]);
    if (length != rows + 1) return -1;
    int64_t total = 0, previous = 1000000;
    for (std::size_t i = 1; i <= rows; ++i) {
        if (input[i] < 1 || input[i] > previous) return -1;
        total += input[i];
        if (total > 1000000) return -1;
        previous = input[i];
    }
    int64_t hooks = 1;
    auto height = rows;
    if (rows) for (int64_t column = 0; column < input[1]; ++column) {
        while (height && input[height] <= column) --height;
        for (std::size_t row = 0; row < height; ++row)
            hooks = hooks * (input[row + 1] - column + static_cast<int64_t>(height - row - 1)) % hook_prime;
    }
    int64_t factorial = 1;
    for (int64_t i = 2; i <= total; ++i) factorial = factorial * i % hook_prime;
    int64_t inverse = 1, exponent = hook_prime - 2;
    while (exponent) {
        if (exponent & 1) inverse = inverse * hooks % hook_prime;
        hooks = hooks * hooks % hook_prime;
        exponent >>= 1;
    }
    return factorial * inverse % hook_prime;
}
