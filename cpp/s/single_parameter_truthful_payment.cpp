#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MaxSteps = 8, MaxInput = 18, MaxOutput = 16, MaxBid = 16;
void put(std::uint8_t *out, std::size_t at, std::int64_t x) {
    std::uint64_t bits = static_cast<std::uint64_t>(x);
    for (std::size_t b = 0; b < 8; ++b) { out[at+b] = static_cast<std::uint8_t>(bits & 255); bits >>= 8; }
}
}

extern "C" std::int64_t single_parameter_truthful_payment(const std::int64_t *v, std::size_t n,
                                                           std::uint8_t *out, std::size_t cap) {
    if (!v || n < 4 || n > MaxInput || v[0] < 0 || v[0] > MaxBid || v[1] < 1 || v[1] > MaxSteps) return -1;
    const auto bid = static_cast<std::size_t>(v[0]), k = static_cast<std::size_t>(v[1]);
    if (n != 2 + 2*k) return -1;
    for (std::size_t i = 0; i < k; ++i) {
        const auto point = v[2+2*i], load = v[3+2*i];
        if (point < 0 || point >= MaxBid || load < 0 || load > MaxBid) return -1;
        if ((i == 0 && point != 0) || (i > 0 && (point <= v[2+2*(i-1)] || load > v[3+2*(i-1)]))) return -1;
    }
    std::int64_t allocation = 0;
    if (bid < MaxBid) for (std::size_t i = 0; i < k && static_cast<std::size_t>(v[2+2*i]) <= bid; ++i) allocation = v[3+2*i];
    std::int64_t area = 0;
    for (std::size_t i = 0; i < k; ++i) {
        const auto start = static_cast<std::size_t>(v[2+2*i]);
        const auto end = i+1 < k ? static_cast<std::size_t>(v[2+2*(i+1)]) : MaxBid;
        const auto left = start > bid ? start : bid;
        if (end > left) area += static_cast<std::int64_t>(end-left) * v[3+2*i];
    }
    const auto payment = static_cast<std::int64_t>(bid) * allocation + area;
    if (!out || cap < MaxOutput) return -2;
    std::array<std::uint8_t, MaxOutput> staged{};
    put(staged.data(), 0, allocation); put(staged.data(), 8, payment);
    for (std::size_t i = 0; i < MaxOutput; ++i) out[i] = staged[i];
    return MaxOutput;
}
