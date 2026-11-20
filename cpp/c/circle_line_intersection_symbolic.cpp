// Independently authored draft; not compiled or run.
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t circle_line_intersection_symbolic(const std::int64_t* input,
        std::size_t length, std::uint8_t* output, std::size_t capacity) {
    if (!input || length != 6) return -1;
    for (std::size_t i = 0; i < 6; ++i)
        if (input[i] < -1000 || input[i] > 1000) return -1;
    const auto x = input[0], y = input[1], r = input[2];
    const auto a = input[3], b = input[4], c = input[5];
    if (r < 1 || (a == 0 && b == 0)) return -1;
    const auto d = a*a+b*b, q = a*x+b*y+c, h = r*r*d-q*q;
    const std::int64_t words[] = {h < 0 ? 0 : h == 0 ? 1 : 2,
                                  x*d-a*q, y*d-b*q, d, -b, a, h};
    const std::size_t count = h < 0 ? 1 : 7, needed = count*8;
    if (!output || capacity < needed) return -2;
    for (std::size_t i = 0; i < count; ++i) {
        const auto bits = static_cast<std::uint64_t>(words[i]);
        for (std::size_t j = 0; j < 8; ++j) output[8*i+j] = static_cast<std::uint8_t>(bits >> (8*j));
    }
    return static_cast<std::int64_t>(needed);
}
