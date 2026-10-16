#include <cmath>
#include <cstddef>
#include <cstdint>
#include <cstring>

namespace {
constexpr std::size_t max_years = 16;
constexpr std::int64_t max_value_micro = 1'000'000'000'000;
constexpr std::int64_t max_rate_ppm = 1'000'000;
constexpr std::int64_t max_units = 1'000'000'000;

void write_f64_le(std::uint8_t *output, std::size_t offset, double value) noexcept {
    std::uint64_t bits;
    std::memcpy(&bits, &value, sizeof(bits));
    for (std::size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
}

extern "C" std::int64_t depreciation(const std::int64_t *values, std::size_t length,
                                      std::uint8_t *output, std::size_t output_capacity) noexcept {
    if (values == nullptr || length < 4 || length > max_years + 4) return -1;
    const auto method = values[0];
    std::size_t years = 0;
    std::int64_t purchase_scaled = 0, residual_scaled = 0;
    double rate = 0.0;
    if (method == 0 || method == 3 || method == 4) {
        if (length != 4 || values[1] < 1 || values[1] > static_cast<std::int64_t>(max_years)) return -1;
        years = static_cast<std::size_t>(values[1]);
        purchase_scaled = values[2]; residual_scaled = values[3];
    } else if (method == 1) {
        if (length != 5 || values[1] < 1 || values[1] > static_cast<std::int64_t>(max_years)
            || values[4] < 1 || values[4] > max_rate_ppm) return -1;
        years = static_cast<std::size_t>(values[1]);
        purchase_scaled = values[2]; residual_scaled = values[3];
        rate = static_cast<double>(values[4]) / 1'000'000.0;
    } else if (method == 2) {
        if (length < 5) return -1;
        years = length - 4;
        if (years > max_years || values[3] < 1 || values[3] > max_units) return -1;
        purchase_scaled = values[1]; residual_scaled = values[2];
        double unit_sum = 0.0;
        for (std::size_t i = 0; i < years; ++i) {
            if (values[4 + i] < -max_units || values[4 + i] > max_units) return -1;
            unit_sum += static_cast<double>(values[4 + i]);
        }
        if (std::abs(unit_sum - static_cast<double>(values[3])) > 1.0e-6 * static_cast<double>(values[3])) return -1;
    } else return -1;

    if (purchase_scaled < 0 || purchase_scaled > max_value_micro
        || residual_scaled < -max_value_micro || residual_scaled > purchase_scaled) return -1;
    const double purchase = static_cast<double>(purchase_scaled) / 1'000'000.0;
    const double residual = static_cast<double>(residual_scaled) / 1'000'000.0;
    const double depreciable_cost = purchase - residual;
    double schedule[max_years]{};

    if (method == 0) {
        const double annual = depreciable_cost / static_cast<double>(years);
        double accumulated = 0.0;
        for (std::size_t period = 0; period < years; ++period) {
            if (period == years - 1) schedule[period] = depreciable_cost - accumulated;
            else { accumulated += annual; schedule[period] = annual; }
        }
    } else if (method == 1) {
        double book_value = purchase;
        for (std::size_t period = 0; period < years; ++period) {
            if (period == years - 1) schedule[period] = book_value - residual;
            else {
                const double expense = std::fmin(book_value * rate, book_value - residual);
                schedule[period] = expense; book_value -= expense;
            }
        }
    } else if (method == 2) {
        const double per_unit = depreciable_cost / static_cast<double>(values[3]);
        double accumulated = 0.0;
        for (std::size_t period = 0; period < years; ++period) {
            if (period == years - 1) schedule[period] = depreciable_cost - accumulated;
            else {
                const double expense = static_cast<double>(values[4 + period]) * per_unit;
                accumulated += expense; schedule[period] = expense;
            }
        }
    } else if (method == 3) {
        const double syd = static_cast<double>(years) * (static_cast<double>(years) + 1.0) / 2.0;
        double accumulated = 0.0;
        for (std::size_t period = 1; period <= years; ++period) {
            if (period == years) schedule[period - 1] = depreciable_cost - accumulated;
            else {
                const double expense = (static_cast<double>(years - period + 1) / syd) * depreciable_cost;
                accumulated += expense; schedule[period - 1] = expense;
            }
        }
    } else {
        const double ddb_rate = 2.0 / static_cast<double>(years);
        double book_value = purchase, accumulated = 0.0;
        for (std::size_t period = 1; period <= years; ++period) {
            const double remaining = static_cast<double>(years - period + 1);
            const double ddb = std::fmax(book_value * ddb_rate, 0.0);
            const double straight_line = std::fmax((book_value - residual) / remaining, 0.0);
            const double expense = std::fmin(std::fmax(ddb, straight_line), book_value - residual);
            if (period == years) schedule[period - 1] = depreciable_cost - accumulated;
            else { accumulated += expense; schedule[period - 1] = expense; book_value -= expense; }
        }
    }

    const std::size_t output_bytes = years * 8;
    if (output == nullptr || output_bytes > output_capacity) return -2;
    for (std::size_t i = 0; i < years; ++i) write_f64_le(output, i * 8, schedule[i]);
    return static_cast<std::int64_t>(output_bytes);
}
