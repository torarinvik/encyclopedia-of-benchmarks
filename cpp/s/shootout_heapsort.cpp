/* Port the generated-double heapsort from the Shootout benchmark. */
#include <cstddef>
#include <cstdint>

namespace {
constexpr int MAX_LENGTH = 8192;
constexpr std::size_t MAX_OUTPUT_BYTES = 9;
constexpr std::int64_t IM = 139968;
constexpr std::int64_t IA = 3877;
constexpr std::int64_t IC = 29573;

void source_heapsort(int n, double *values)
{
    int i, j;
    int ir = n;
    int l = (n >> 1) + 1;
    double rra;
    for (;;) {
        if (l > 1) {
            rra = values[--l];
        } else {
            rra = values[ir];
            values[ir] = values[1];
            if (--ir == 1) {
                values[1] = rra;
                return;
            }
        }
        i = l;
        j = l << 1;
        while (j <= ir) {
            if (j < ir && values[j] < values[j + 1]) ++j;
            if (rra < values[j]) {
                values[i] = values[j];
                i = j;
                j += i;
            } else {
                j = ir + 1;
            }
        }
        values[i] = rra;
    }
}

void write_fixed_six(double value, std::uint8_t *output)
{
    const auto millionths = static_cast<std::uint32_t>(value * 1000000.0 + 0.5);
    const auto whole = millionths / 1000000u;
    auto fraction = millionths % 1000000u;
    output[0] = static_cast<std::uint8_t>('0' + whole);
    output[1] = static_cast<std::uint8_t>('.');
    std::uint32_t divisor = 100000u;
    for (std::size_t index = 2; index < 8; ++index) {
        output[index] = static_cast<std::uint8_t>('0' + (fraction / divisor) % 10u);
        divisor /= 10u;
    }
    output[8] = static_cast<std::uint8_t>('\n');
}
}

extern "C" std::int64_t shootout_heapsort(std::int64_t length, std::uint8_t *output,
                                            std::size_t output_capacity) noexcept
{
    if (length < 2 || length > MAX_LENGTH) return -1;
    if (output == nullptr || output_capacity < MAX_OUTPUT_BYTES) return -2;

    const int n = static_cast<int>(length);
    double values[MAX_LENGTH + 1];
    std::int64_t state = 42;
    for (int index = 1; index <= n; ++index) {
        state = (state * IA + IC) % IM;
        values[index] = 1.0 * static_cast<double>(state) / static_cast<double>(IM);
    }
    source_heapsort(n, values);
    write_fixed_six(values[n], output);
    return static_cast<std::int64_t>(MAX_OUTPUT_BYTES);
}
