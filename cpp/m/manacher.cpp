/* Return the leftmost longest ASCII alphanumeric palindrome with Manacher's algorithm. */
#include <cstddef>
#include <cstdint>

static bool is_ascii_alphanumeric(std::int64_t value)
{
    return (value >= '0' && value <= '9') ||
           (value >= 'A' && value <= 'Z') ||
           (value >= 'a' && value <= 'z');
}

static bool transformed_equal(const std::int64_t *values, std::size_t left,
                              std::size_t right)
{
    if ((left & 1U) != (right & 1U)) return false;
    return (left & 1U) == 0 || values[left / 2] == values[right / 2];
}

// Return the leftmost longest ASCII alphanumeric palindrome with Manacher's algorithm.
extern "C" std::int64_t manacher(
    const std::int64_t *values, std::size_t length,
    std::uint8_t *output, std::size_t output_capacity) noexcept
{
    if (length == 0 || length > 1000 || values == nullptr) return -1;
    for (std::size_t index = 0; index < length; ++index)
        if (!is_ascii_alphanumeric(values[index])) return -1;

    std::size_t radii[2001] = {};
    const std::size_t transformed_length = 2 * length + 1;
    std::size_t center = 0, right = 0;
    std::size_t best_center = 0, best_radius = 0;
    for (std::size_t index = 0; index < transformed_length; ++index) {
        std::size_t radius = 0;
        if (index < right) {
            const std::size_t mirror = 2 * center - index;
            const std::size_t remaining = right - index;
            radius = radii[mirror] < remaining ? radii[mirror] : remaining;
        }
        while (radius < index && radius < transformed_length - 1 - index &&
               transformed_equal(values, index - radius - 1, index + radius + 1)) {
            ++radius;
        }
        radii[index] = radius;
        if (index + radius > right) {
            center = index;
            right = index + radius;
        }
        if (radius > best_radius) {
            best_center = index;
            best_radius = radius;
        }
    }

    const std::size_t best_start = (best_center - best_radius) / 2;
    if (output_capacity < best_radius || output == nullptr) return -2;
    for (std::size_t index = 0; index < best_radius; ++index)
        output[index] = static_cast<std::uint8_t>(values[best_start + index]);
    return static_cast<std::int64_t>(best_radius);
}
