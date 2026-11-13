#include <math.h>
#include <stddef.h>
#include <stdint.h>

#define MAX_INPUT_LENGTH 5

static int integer_field(double value, int low, int high, int *decoded)
{
    if (!isfinite(value) || value < low || value > high || trunc(value) != value) return 0;
    *decoded = (int)value;
    return 1;
}

static double integrand(int id, double x)
{
    if (id == 0) return exp(x);
    if (id == 1) return x * x * x * x * x;
    if (id == 2) return 1.0 / (1.0 + x * x);
    return cos(x);
}

static double romberg(int id, double a, double b, int levels)
{
    if (a == b) return 0.0;
    double previous[9] = {0.0};
    previous[0] = (b - a) * (integrand(id, a) + integrand(id, b)) * 0.5;
    for (int level = 1; level <= levels; ++level) {
        int interval_count = 1 << level;
        double spacing = (b - a) / (double)interval_count;
        double added = 0.0;
        for (int index = 1; index < interval_count; index += 2)
            added += integrand(id, a + (double)index * spacing);
        double current[9] = {0.0};
        current[0] = previous[0] * 0.5 + spacing * added;
        double factor = 4.0;
        for (int order = 1; order <= level; ++order) {
            current[order] = current[order - 1] +
                (current[order - 1] - previous[order - 1]) / (factor - 1.0);
            factor *= 4.0;
        }
        for (int order = 0; order <= level; ++order) previous[order] = current[order];
    }
    return previous[levels];
}

int64_t romberg_integration(const double *input, size_t input_length,
                            double *output, size_t output_capacity)
{
    if (input == NULL || input_length != 4 || input_length > MAX_INPUT_LENGTH) return -1;
    int id, a_micro, b_micro, levels;
    if (!integer_field(input[0], 0, 3, &id) ||
        !integer_field(input[1], -1000000, 1000000, &a_micro) ||
        !integer_field(input[2], -1000000, 1000000, &b_micro) ||
        !integer_field(input[3], 3, 8, &levels) || a_micro > b_micro) return -1;
    if (output == NULL || output_capacity < 1) return -2;
    double result = romberg(id, (double)a_micro / 1000000.0,
                            (double)b_micro / 1000000.0, levels);
    if (!isfinite(result)) return -1;
    output[0] = result;
    return 1;
}
