#include <cmath>
#include <cstddef>
#include <cstdint>

namespace {
constexpr double invalid_result = -1.0e300;

void coefficients(std::int64_t kind, double frequency, double samplerate,
                  double gain_db, double q_factor, double output[6]) noexcept {
    const double w0 = 6.283185307179586476925286766559 * frequency / samplerate;
    const double sine = std::sin(w0), cosine = std::cos(w0);
    const double alpha = sine / (2.0 * q_factor);
    double a0 = 1.0 + alpha, a1 = -2.0 * cosine, a2 = 1.0 - alpha;
    double b0, b1, b2;
    if (kind == 0) {
        b0 = (1.0 - cosine) / 2.0; b1 = 1.0 - cosine; b2 = b0;
    } else if (kind == 1) {
        b0 = (1.0 + cosine) / 2.0; b1 = -1.0 - cosine; b2 = b0;
    } else if (kind == 2) {
        b0 = sine / 2.0; b1 = 0.0; b2 = -b0;
    } else if (kind == 3) {
        b0 = 1.0 - alpha; b1 = -2.0 * cosine; b2 = 1.0 + alpha;
        a0 = b2; a1 = b1; a2 = b0;
    } else if (kind == 4) {
        const double big_a = std::pow(10.0, gain_db / 40.0);
        b0 = 1.0 + alpha * big_a; b1 = -2.0 * cosine; b2 = 1.0 - alpha * big_a;
        a0 = 1.0 + alpha / big_a; a1 = -2.0 * cosine; a2 = 1.0 - alpha / big_a;
    } else if (kind == 5 || kind == 6) {
        const double big_a = std::pow(10.0, gain_db / 40.0);
        const double pmc = (big_a + 1.0) - (big_a - 1.0) * cosine;
        const double ppmc = (big_a + 1.0) + (big_a - 1.0) * cosine;
        const double mpc = (big_a - 1.0) - (big_a + 1.0) * cosine;
        const double pmpc = (big_a - 1.0) + (big_a + 1.0) * cosine;
        const double aa2 = 2.0 * std::sqrt(big_a) * alpha;
        if (kind == 5) {
            b0 = big_a * (pmc + aa2); b1 = 2.0 * big_a * mpc; b2 = big_a * (pmc - aa2);
            a0 = ppmc + aa2; a1 = -2.0 * pmpc; a2 = ppmc - aa2;
        } else {
            b0 = big_a * (ppmc + aa2); b1 = -2.0 * big_a * pmpc; b2 = big_a * (ppmc - aa2);
            a0 = pmc + aa2; a1 = 2.0 * mpc; a2 = pmc - aa2;
        }
    } else if (kind == 7) {
        b0 = 1.0; b1 = -2.0 * cosine; b2 = 1.0;
    } else {
        b0 = alpha; b1 = 0.0; b2 = -alpha;
    }
    output[0] = a0; output[1] = a1; output[2] = a2;
    output[3] = b0; output[4] = b1; output[5] = b2;
}
}

extern "C" double butterworth_filter(const std::int64_t *values, std::size_t length) noexcept {
    if (values == nullptr || length != 6) return invalid_result;
    const auto kind = values[0], coefficient_index = values[1];
    const auto frequency = values[2], samplerate = values[3];
    const auto gain_milli_db = values[4], q_micro = values[5];
    if (kind < 0 || kind > 8 || coefficient_index < 0 || coefficient_index > 5 ||
        frequency < 1 || frequency > 95999 || samplerate < 1 || samplerate > 192000 ||
        2 * frequency >= samplerate) return invalid_result;
    if (q_micro != -1 && (q_micro < 1 || q_micro > 10000000)) return invalid_result;
    const bool needs_gain = kind >= 4 && kind <= 6;
    if (needs_gain) {
        if (gain_milli_db < -60000 || gain_milli_db > 60000) return invalid_result;
    } else if (gain_milli_db != 0) return invalid_result;
    const double gain_db = needs_gain ? static_cast<double>(gain_milli_db) / 1000.0 : 0.0;
    const double q_factor = q_micro == -1 ? 1.0 / std::sqrt(2.0)
                                          : static_cast<double>(q_micro) / 1000000.0;
    double output[6];
    coefficients(kind, static_cast<double>(frequency), static_cast<double>(samplerate),
                 gain_db, q_factor, output);
    return output[coefficient_index];
}
