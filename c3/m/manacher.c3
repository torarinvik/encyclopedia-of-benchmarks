module manacher;

fn bool is_ascii_alphanumeric(long value)
{
    return (value >= '0' && value <= '9') ||
           (value >= 'A' && value <= 'Z') ||
           (value >= 'a' && value <= 'z');
}

fn bool transformed_equal(long* values, usz left, usz right)
{
    if ((left % 2) != (right % 2)) return false;
    return (left % 2) == 0 || values[left / 2] == values[right / 2];
}

// Return the leftmost longest ASCII alphanumeric palindrome with Manacher's algorithm.
fn long manacher(long* values, usz length, char* output, usz output_capacity)
    @export("manacher")
{
    if (length == 0 || length > 1000 || values == null) return -1;
    for (usz index = 0; index < length; index++) {
        if (!is_ascii_alphanumeric(values[index])) return -1;
    }

    usz[2001] radii = {0};
    usz transformed_length = 2 * length + 1;
    usz center = 0;
    usz right = 0;
    usz best_center = 0;
    usz best_radius = 0;
    for (usz index = 0; index < transformed_length; index++) {
        usz radius = 0;
        if (index < right) {
            usz mirror = 2 * center - index;
            usz remaining = right - index;
            radius = radii[mirror] < remaining ? radii[mirror] : remaining;
        }
        while (radius < index && radius < transformed_length - 1 - index &&
               transformed_equal(values, index - radius - 1, index + radius + 1)) {
            radius++;
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

    usz best_start = (best_center - best_radius) / 2;
    if (output_capacity < best_radius || output == null) return -2;
    for (usz index = 0; index < best_radius; index++) {
        output[index] = (char)values[best_start + index];
    }
    return (long)best_radius;
}
