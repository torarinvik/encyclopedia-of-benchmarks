/* Return the leftmost longest ASCII alphanumeric palindrome with Manacher's algorithm. */
#include <stddef.h>
#include <stdint.h>

static int is_ascii_alphanumeric(int64_t value)
{
    return (value >= '0' && value <= '9') ||
           (value >= 'A' && value <= 'Z') ||
           (value >= 'a' && value <= 'z');
}

static int transformed_equal(const int64_t *values, size_t left, size_t right)
{
    if ((left & 1U) != (right & 1U)) return 0;
    return (left & 1U) == 0 || values[left / 2] == values[right / 2];
}

int64_t manacher(const int64_t *values, size_t length,
                 uint8_t *output, size_t output_capacity)
{
    if (length == 0 || length > 1000 || values == NULL) return -1;
    for (size_t index = 0; index < length; ++index)
        if (!is_ascii_alphanumeric(values[index])) return -1;

    size_t radii[2001] = {0};
    const size_t transformed_length = 2 * length + 1;
    size_t center = 0, right = 0;
    size_t best_center = 0, best_radius = 0;
    for (size_t index = 0; index < transformed_length; ++index) {
        size_t radius = 0;
        if (index < right) {
            const size_t mirror = 2 * center - index;
            radius = radii[mirror] < right - index ? radii[mirror] : right - index;
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

    const size_t best_start = (best_center - best_radius) / 2;
    if (output_capacity < best_radius || output == NULL) return -2;
    for (size_t index = 0; index < best_radius; ++index)
        output[index] = (uint8_t)values[best_start + index];
    return (int64_t)best_radius;
}
