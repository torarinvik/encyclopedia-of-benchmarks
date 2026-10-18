#include <cstddef>
#include <cstdint>

extern "C" std::int64_t k_means_rust(const std::int64_t* input, std::size_t length) noexcept {
    constexpr std::int64_t u53_max = INT64_C(9007199254740991);
    constexpr double u53_denominator = 9007199254740992.0;
    if (input == nullptr || length != 10 || input[0] != 4) return -1;
    const std::int64_t max_iter = input[1];
    if (max_iter < 1 || max_iter > 16) return -1;
    const std::int64_t draw0 = input[2];
    const std::int64_t draw1 = input[4];
    if (input[3] != 0 || input[5] != 0 || draw0 < 0 || draw0 > u53_max ||
        draw1 < 0 || draw1 > u53_max || draw0 == draw1) return -1;

    double points[4]{};
    for (std::size_t index = 0; index < 4; ++index) {
        const std::int64_t coordinate = input[index + 6];
        if (coordinate < -16 || coordinate > 16 ||
            (index > 0 && input[index + 5] >= coordinate)) return -1;
        points[index] = static_cast<double>(coordinate);
    }
    if (input[7] >= 0 || input[8] <= 1) return -1;

    double centers[2][2] = {
        {static_cast<double>(draw0) / u53_denominator, 0.0},
        {static_cast<double>(draw1) / u53_denominator, 0.0},
    };
    std::int64_t labels[4]{};
    for (std::int64_t pass = 0; pass < max_iter; ++pass) {
        double sums[2][2]{{0.0, 0.0}, {0.0, 0.0}};
        std::size_t counts[2]{};
        for (std::size_t index = 0; index < 4; ++index) {
            const double dx0 = points[index] - centers[0][0];
            const double dy0 = -centers[0][1];
            const double dx1 = points[index] - centers[1][0];
            const double dy1 = -centers[1][1];
            const double distance0 = dx0 * dx0 + dy0 * dy0;
            const double distance1 = dx1 * dx1 + dy1 * dy1;
            const std::size_t cluster = distance1 < distance0 ? 1 : 0;
            labels[index] = static_cast<std::int64_t>(cluster);
            sums[cluster][0] += points[index];
            sums[cluster][1] += 0.0;
            ++counts[cluster];
        }
        if (counts[0] == 0 || counts[1] == 0) return -1;
        for (std::size_t cluster = 0; cluster < 2; ++cluster) {
            centers[cluster][0] = sums[cluster][0] / static_cast<double>(counts[cluster]);
            centers[cluster][1] = sums[cluster][1] / static_cast<double>(counts[cluster]);
        }
    }

    std::int64_t packed = 0;
    for (std::size_t index = 0; index < 4; ++index)
        packed += labels[index] * (INT64_C(1) << index);
    return packed;
}
