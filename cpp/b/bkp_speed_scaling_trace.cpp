#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t e_num = 271828, e_den = 100000, em1_num = 171828;
constexpr std::size_t max_jobs = 4, max_samples = 8, max_bytes = 136;
std::int64_t gcd64(std::int64_t a, std::int64_t b) {
    while (b) { const auto r = a % b; a = b; b = r; }
    return a < 0 ? -a : a;
}
void consider(const std::array<std::int64_t,max_jobs>& r,
    const std::array<std::int64_t,max_jobs>& d,
    const std::array<std::int64_t,max_jobs>& w, std::size_t n,
    std::int64_t t, std::int64_t x_num, std::int64_t x_den,
    std::int64_t& best_num, std::int64_t& best_den) {
    const auto delta = x_num - t * x_den;
    if (delta <= 0) return;
    const auto left = e_num * t * x_den - em1_num * x_num;
    std::int64_t total = 0;
    for (std::size_t j = 0; j < n; ++j)
        if (r[j] <= t && left <= e_den * x_den * r[j] && d[j] * x_den <= x_num) total += w[j];
    const auto num = total * x_den;
    if (num * best_den > best_num * delta) { best_num = num; best_den = delta; }
}
void store(std::uint8_t* out, std::size_t at, std::int64_t value) {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t b = 0; b < 8; ++b) out[at+b] = static_cast<std::uint8_t>(bits >> (8*b));
}
}

extern "C" std::int64_t bkp_speed_scaling_trace(const std::int64_t* input,
    std::size_t length, std::uint8_t* output, std::size_t capacity) {
    if (input == nullptr || length < 2 || length > 31) return -1;
    if (input[0] < 1 || input[0] > 4 || input[1] < 1 || input[1] > 8) return -1;
    const auto n = static_cast<std::size_t>(input[0]);
    const auto samples = static_cast<std::size_t>(input[1]);
    if (length != 2 + 3*n + 2*samples) return -1;
    std::array<std::int64_t,max_jobs> release{}, deadline{}, work{};
    for (std::size_t j = 0; j < n; ++j) {
        release[j] = input[2+3*j]; deadline[j] = input[3+3*j]; work[j] = input[4+3*j];
        if (release[j] < 0 || release[j] >= deadline[j] || deadline[j] > 8 || work[j] < 1 || work[j] > 8) return -1;
    }
    std::array<std::int64_t,17> values{};
    values[0] = static_cast<std::int64_t>(samples);
    for (std::size_t s = 0; s < samples; ++s) {
        const auto t = input[2+3*n+2*s], mask = input[3+3*n+2*s];
        if (t < 0 || t > 8 || mask < 0 || mask >= (INT64_C(1) << n)) return -1;
        for (std::size_t j=0;j<n;++j) if ((mask & (INT64_C(1)<<j)) && release[j]>t) return -1;
        std::int64_t bn=0, bd=1;
        if (mask) for (std::size_t j=0;j<n;++j) if (release[j]<=t) {
            if (deadline[j]>t) consider(release,deadline,work,n,t,deadline[j],1,bn,bd);
            if (release[j]<t) consider(release,deadline,work,n,t,e_num*t-e_den*release[j],em1_num,bn,bd);
        }
        const auto g=gcd64(bn,bd);
        values[1+2*s]=bn/g; values[2+2*s]=bd/g;
    }
    const auto bytes=8*(1+2*samples);
    if (output==nullptr || capacity<bytes) return -2;
    std::array<std::uint8_t,max_bytes> staged{};
    for (std::size_t i=0;i<1+2*samples;++i) store(staged.data(),8*i,values[i]);
    for (std::size_t i=0;i<bytes;++i) output[i]=staged[i];
    return static_cast<std::int64_t>(bytes);
}
