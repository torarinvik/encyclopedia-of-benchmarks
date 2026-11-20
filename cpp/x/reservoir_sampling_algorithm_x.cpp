#include <array>
#include <cstddef>
#include <cstdint>

static std::int64_t falling(std::int64_t top, std::size_t k) {
    std::int64_t product = 1;
    for (std::size_t i = 0; i < k; ++i) product *= top-static_cast<std::int64_t>(i);
    return product;
}

extern "C" std::int64_t reservoir_sampling_algorithm_x(const std::int64_t* input, std::size_t length, std::uint8_t* output, std::size_t capacity) {
    if (input == nullptr || length < 3 || length > 49 || input[0] < 1 || input[0] > 16) return -1;
    const auto n = static_cast<std::size_t>(input[0]);
    if (input[1] < 1 || input[1] > 8) return -1;
    const auto k = static_cast<std::size_t>(input[1]);
    if ((k & (k-1)) != 0 || k > n || length != 2+n+2*(n-k)) return -1;
    for (std::size_t i = 0; i < n; ++i) if (input[2+i] < -1000000 || input[2+i] > 1000000) return -1;
    for (std::size_t i = 2+n; i < length; ++i) if (input[i] < 0 || input[i] > 4294967295LL) return -1;
    if (output == nullptr || capacity < 8*k) return -2;
    std::array<std::int64_t, 8> sample{};
    for (std::size_t i = 0; i < k; ++i) sample[i] = input[2+i];
    std::size_t processed = k, attempt = 0;
    while (processed < n) {
        const auto draw = input[2+n+2*attempt], slot_draw = input[2+n+2*attempt+1];
        ++attempt;
        auto numerator = falling(static_cast<std::int64_t>(processed), k);
        auto denominator = falling(static_cast<std::int64_t>(processed)+1, k);
        auto divisor = numerator;
        auto other = denominator;
        while (other != 0) { const auto r = divisor % other; divisor = other; other = r; }
        numerator /= divisor; denominator /= divisor;
        const auto max_skip = n-processed-1;
        std::size_t selected = 0;
        bool found = false;
        for (std::size_t skip = 0; skip <= max_skip; ++skip) {
            if (numerator*4294967297LL <= (draw+1)*denominator) { selected = skip; found = true; break; }
            if (skip < max_skip) {
                const auto top = static_cast<std::int64_t>(processed+skip+1);
                numerator *= top+1-static_cast<std::int64_t>(k); denominator *= top+1;
                divisor = numerator; other = denominator;
                while (other != 0) { const auto r = divisor % other; divisor = other; other = r; }
                numerator /= divisor; denominator /= divisor;
            }
        }
        if (!found) break;
        sample[static_cast<std::size_t>(slot_draw % static_cast<std::int64_t>(k))] = input[2+processed+selected];
        processed += selected+1;
    }
    for (std::size_t i = 0; i < k; ++i) {
        auto bits = static_cast<std::uint64_t>(sample[i]);
        for (std::size_t j = 0; j < 8; ++j) { output[8*i+j] = static_cast<std::uint8_t>(bits & 255u); bits >>= 8; }
    }
    return static_cast<std::int64_t>(8*k);
}
