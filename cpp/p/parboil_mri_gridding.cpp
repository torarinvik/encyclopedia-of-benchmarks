#include <cmath>
#include <cstddef>
#include <cstdint>

namespace {
constexpr int SIDE = 3, CELLS = 27, MAX_SAMPLES = 4;
constexpr float WIDTH = 2.5f, OVERSAMPLE = 0.608933f;
constexpr float COEFF[15] = {
    0.210580722890567e-22f, 0.380715242345326e-19f, 0.479440257548300e-16f,
    0.435125971262668e-13f, 0.300931127112960e-10f, 0.160224679395361e-7f,
    0.654858370096785e-5f, 0.202591084143397e-2f, 0.463076284721000e0f,
    0.754337328948189e2f, 0.830792541809429e4f, 0.571661130563785e6f,
    0.216415572361227e8f, 0.356644482244025e9f, 0.144048298227235e10f
};
float decode(std::int64_t raw) { return static_cast<float>(raw) / 1000000.0f; }
float kernel(float value) {
    const float z = value * value;
    float num = COEFF[0];
    for (int i = 1; i < 15; ++i) { const float product = z * num; num = product + COEFF[i]; }
    float den = z - 0.307646912682801e4f;
    den = z * den; den = den + 0.347626332405882e7f;
    den = z * den; den = den - 0.144048298227235e10f;
    return -num / den;
}
float beta_value() {
    float first = 4.0f * WIDTH; first = first * WIDTH;
    const float divisor = OVERSAMPLE * OVERSAMPLE; first = first / divisor;
    const double shifted = static_cast<double>(OVERSAMPLE) - 0.5;
    double arg = static_cast<double>(first) * shifted; arg = arg * shifted; arg = arg - 0.8;
    return static_cast<float>(3.14159265359 * std::sqrt(arg));
}
float weight(float v, float inverse_cutoff2, float beta, float sdc) {
    const float product = v * inverse_cutoff2;
    const double arg = 1.0 - static_cast<double>(product);
    const float kernel_arg = static_cast<float>(static_cast<double>(beta) * std::sqrt(arg));
    return kernel(kernel_arg) * sdc;
}
int lower(float k, float cutoff) {
    const float delta = k - cutoff;
    const double value = static_cast<double>(delta) < 0.0 ? 0.0 : static_cast<double>(delta);
    return static_cast<int>(static_cast<std::uint32_t>(value));
}
int upper(float k, float cutoff) {
    const float sum = k + cutoff;
    const double value = static_cast<double>(sum) > 2.0 ? 2.0 : static_cast<double>(sum);
    return static_cast<int>(static_cast<std::uint32_t>(value));
}
std::int64_t quantize(float value) {
    const float scaled = value * 1000.0f;
    const float magnitude = scaled < 0.0f ? -scaled : scaled;
    std::int64_t whole = static_cast<std::int64_t>(magnitude);
    if (magnitude - static_cast<float>(whole) >= 0.5f) ++whole;
    return scaled < 0.0f ? -whole : whole;
}
}

extern "C" std::int64_t parboil_mri_gridding(const std::int64_t *input, std::size_t length) {
    if (input == nullptr || length < 1 || length > 25) return -1;
    const std::int64_t n = input[0];
    if (n < 0 || n > MAX_SAMPLES || length != static_cast<std::size_t>(1 + 6*n)) return -1;
    for (std::int64_t s = 0; s < n; ++s) {
        const std::size_t p = 1 + static_cast<std::size_t>(s)*6;
        for (int a = 0; a < 3; ++a) if (input[p+a] != 0 && input[p+a] != 1000000 && input[p+a] != 2000000) return -1;
        if (input[p+3] < -1000000 || input[p+3] > 1000000 || input[p+4] < -1000000 || input[p+4] > 1000000 || input[p+5] < 0 || input[p+5] > 1000000) return -1;
    }
    float real[CELLS]{}, imag[CELLS]{}, density[CELLS]{};
    const float cutoff = static_cast<float>(static_cast<double>(WIDTH) / 2.0);
    const float cutoff2 = cutoff * cutoff;
    const float inverse = 1.0f / cutoff2;
    const float beta = beta_value();
    for (std::int64_t s = 0; s < n; ++s) {
        const std::size_t p = 1 + static_cast<std::size_t>(s)*6;
        const float kx=decode(input[p]), ky=decode(input[p+1]), kz=decode(input[p+2]);
        const float sr=decode(input[p+3]), si=decode(input[p+4]), sdc=decode(input[p+5]);
        if (!(sr != 0.0f || si != 0.0f) || sdc == 0.0f) continue;
        const int x0=lower(kx,cutoff), x1=upper(kx,cutoff), y0=lower(ky,cutoff), y1=upper(ky,cutoff), z0=lower(kz,cutoff), z1=upper(kz,cutoff);
        for (int z=z0; z<=z1; ++z) {
            const float dz=kz-static_cast<float>(z), dz2=dz*dz;
            if (dz2 < cutoff2) for (int y=y0; y<=y1; ++y) {
                const float dy=ky-static_cast<float>(y), dy2=dy*dy, yz=dz2+dy2;
                if (yz < cutoff2) for (int x=x0; x<=x1; ++x) {
                    const float dx=kx-static_cast<float>(x), dx2=dx*dx, v=yz+dx2;
                    if (v < cutoff2) {
                        const int index=x+SIDE*y+SIDE*SIDE*z;
                        const float w=weight(v,inverse,beta,sdc);
                        const float dr=w*sr, di=w*si;
                        real[index]=real[index]+dr; imag[index]=imag[index]+di;
                        density[index]=static_cast<float>(static_cast<double>(density[index])+1.0);
                    }
                }
            }
        }
    }
    std::int64_t checksum=0;
    for (int i=0;i<CELLS;++i) checksum += static_cast<std::int64_t>(i+1)*(quantize(real[i])+quantize(imag[i])+static_cast<std::int64_t>(density[i]));
    return checksum;
}
