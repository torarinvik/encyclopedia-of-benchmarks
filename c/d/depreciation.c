#include <math.h>
#include <stddef.h>
#include <stdint.h>
#include <string.h>

#define MAX_YEARS 16
#define MAX_VALUE_MICRO 1000000000000LL
#define MAX_RATE_PPM 1000000LL
#define MAX_UNITS 1000000000LL

static void write_f64_le(uint8_t *output, size_t offset, double value) {
    uint64_t bits;
    memcpy(&bits, &value, sizeof(bits));
    for (size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t depreciation(const int64_t *values, size_t length,
                     uint8_t *output, size_t output_capacity) {
    if (values == NULL || length < 4 || length > MAX_YEARS + 4) return -1;
    const int64_t method = values[0];
    size_t years = 0;
    int64_t purchase_scaled = 0, residual_scaled = 0;
    double rate = 0.0;
    if (method == 0 || method == 3 || method == 4) {
        if (length != 4) return -1;
        if (values[1] < 1 || values[1] > MAX_YEARS) return -1;
        years = (size_t)values[1];
        purchase_scaled = values[2]; residual_scaled = values[3];
    } else if (method == 1) {
        if (length != 5 || values[1] < 1 || values[1] > MAX_YEARS
            || values[4] < 1 || values[4] > MAX_RATE_PPM) return -1;
        years = (size_t)values[1];
        purchase_scaled = values[2]; residual_scaled = values[3];
        rate = (double)values[4] / 1000000.0;
    } else if (method == 2) {
        if (length < 5) return -1;
        years = length - 4;
        if (years > MAX_YEARS || values[3] < 1 || values[3] > MAX_UNITS) return -1;
        purchase_scaled = values[1]; residual_scaled = values[2];
        double unit_sum = 0.0;
        for (size_t i = 0; i < years; ++i) {
            int64_t units = values[4 + i];
            if (units < -MAX_UNITS || units > MAX_UNITS) return -1;
            unit_sum += (double)units;
        }
        if (fabs(unit_sum - (double)values[3]) > 1.0e-6 * (double)values[3]) return -1;
    } else return -1;

    if (purchase_scaled < 0 || purchase_scaled > MAX_VALUE_MICRO
        || residual_scaled < -MAX_VALUE_MICRO || residual_scaled > purchase_scaled) return -1;
    const double purchase = (double)purchase_scaled / 1000000.0;
    const double residual = (double)residual_scaled / 1000000.0;
    const double depreciable_cost = purchase - residual;
    double schedule[MAX_YEARS] = {0};

    if (method == 0) {
        const double annual = depreciable_cost / (double)years;
        double accumulated = 0.0;
        for (size_t period = 0; period < years; ++period) {
            if (period == years - 1) schedule[period] = depreciable_cost - accumulated;
            else { accumulated += annual; schedule[period] = annual; }
        }
    } else if (method == 1) {
        double book_value = purchase;
        for (size_t period = 0; period < years; ++period) {
            if (period == years - 1) schedule[period] = book_value - residual;
            else {
                double expense = fmin(book_value * rate, book_value - residual);
                schedule[period] = expense;
                book_value -= expense;
            }
        }
    } else if (method == 2) {
        const double per_unit = depreciable_cost / (double)values[3];
        double accumulated = 0.0;
        for (size_t period = 0; period < years; ++period) {
            if (period == years - 1) schedule[period] = depreciable_cost - accumulated;
            else {
                double expense = (double)values[4 + period] * per_unit;
                accumulated += expense;
                schedule[period] = expense;
            }
        }
    } else if (method == 3) {
        const double syd = (double)years * ((double)years + 1.0) / 2.0;
        double accumulated = 0.0;
        for (size_t period = 1; period <= years; ++period) {
            if (period == years) schedule[period - 1] = depreciable_cost - accumulated;
            else {
                double expense = ((double)(years - period + 1) / syd) * depreciable_cost;
                accumulated += expense;
                schedule[period - 1] = expense;
            }
        }
    } else {
        const double ddb_rate = 2.0 / (double)years;
        double book_value = purchase, accumulated = 0.0;
        for (size_t period = 1; period <= years; ++period) {
            const double remaining = (double)(years - period + 1);
            double ddb = fmax(book_value * ddb_rate, 0.0);
            double straight_line = fmax((book_value - residual) / remaining, 0.0);
            double expense = fmin(fmax(ddb, straight_line), book_value - residual);
            if (period == years) schedule[period - 1] = depreciable_cost - accumulated;
            else { accumulated += expense; schedule[period - 1] = expense; book_value -= expense; }
        }
    }

    const size_t output_bytes = years * 8;
    if (output == NULL || output_bytes > output_capacity) return -2;
    for (size_t i = 0; i < years; ++i) write_f64_le(output, i * 8, schedule[i]);
    return (int64_t)output_bytes;
}
