/* Clean-room bounded simulator for the Embench NSicherNeu Petri/T-Net path. */
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t nsichneu(const std::int64_t *input, std::size_t length,
                                 std::uint8_t *output, std::size_t capacity) noexcept
{
    constexpr std::size_t input_count = 9;
    constexpr std::size_t output_count = 17;
    constexpr std::int64_t max_runs = 64;
    if (input == nullptr || length != input_count || input[0] < 1 || input[0] > max_runs)
        return -1;
    for (std::size_t index = 1; index < length; ++index)
        if (input[index] < -1000 || input[index] > 1000) return -1;
    if (output == nullptr || capacity < output_count * 8) return -2;

    std::int64_t p1[3] = {input[1], input[2], input[3]};
    std::int64_t p2[5] = {input[4], input[5], input[6], input[7], input[8]};
    std::int64_t p3[6] = {};
    std::int64_t p1_count = 3;
    std::int64_t p2_count = 5;
    std::int64_t p3_count = 0;

    for (std::int64_t run = 0; run < input[0]; ++run) {
        p1_count = 3;
        p2_count = 5;
        p3_count = 0;
        for (std::size_t first = 0; first < 3; ++first) {
            for (std::size_t second = 0; second < 3; ++second) {
                if (second == first) continue;
                for (std::size_t third = 0; third < 3; ++third) {
                    if (third == first || third == second) continue;
                    if (p1_count >= 3 && p3_count + 3 <= 6 && p1[second] == p1[third]) {
                        const std::int64_t x = p1[first];
                        const std::int64_t y = p1[second];
                        if (x < y) {
                            p1_count -= 3;
                            p3[p3_count] = x;
                            p3[p3_count + 1] = y;
                            p3[p3_count + 2] = x - y;
                            p3_count += 3;
                        }
                    }
                }
            }
        }

        for (std::size_t subset_number = 0; subset_number < 5; ++subset_number) {
            const std::size_t omitted = 4 - subset_number;
            std::size_t subset[4];
            std::size_t count = 0;
            for (std::size_t index = 0; index < 5; ++index)
                if (index != omitted) subset[count++] = index;
            for (std::size_t a = 0; a < 4; ++a) {
                for (std::size_t b = 0; b < 4; ++b) {
                    if (b == a) continue;
                    for (std::size_t c = 0; c < 4; ++c) {
                        if (c == a || c == b) continue;
                        for (std::size_t d = 0; d < 4; ++d) {
                            if (d == a || d == b || d == c) continue;
                            const std::size_t i0 = subset[a];
                            const std::size_t i1 = subset[b];
                            const std::size_t i2 = subset[c];
                            const std::size_t i3 = subset[d];
                            if (p2_count >= 4 && p3_count + 3 <= 6 &&
                                p2[i1] == p2[i2] && p2[i1] == p2[i3]) {
                                const std::int64_t x = p2[i0];
                                const std::int64_t y = p2[i1];
                                if (y > x) {
                                    p2_count -= 4;
                                    p3[p3_count] = x;
                                    p3[p3_count + 1] = y;
                                    p3[p3_count + 2] = x + y;
                                    p3_count += 3;
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    std::int64_t snapshot[output_count];
    std::size_t position = 0;
    snapshot[position++] = p1_count;
    for (std::size_t index = 0; index < 3; ++index) snapshot[position++] = p1[index];
    snapshot[position++] = p2_count;
    for (std::size_t index = 0; index < 5; ++index) snapshot[position++] = p2[index];
    snapshot[position++] = p3_count;
    for (std::size_t index = 0; index < 6; ++index) snapshot[position++] = p3[index];
    for (std::size_t index = 0; index < output_count; ++index) {
        const std::uint64_t bits = static_cast<std::uint64_t>(snapshot[index]);
        for (std::size_t byte = 0; byte < 8; ++byte)
            output[index * 8 + byte] = static_cast<std::uint8_t>(bits >> (byte * 8));
    }
    return static_cast<std::int64_t>(output_count * 8);
}
