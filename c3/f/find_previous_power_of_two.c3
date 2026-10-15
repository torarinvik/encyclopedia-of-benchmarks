module find_previous_power_of_two;

// Preserve the pinned source's repeated-doubling search on its i32 domain.
fn long find_previous_power_of_two(long number) @export("find_previous_power_of_two")
{
    if (number < 0 || number > 2147483647) return -1;
    if (number == 0) return 0;

    long power = 1;
    while (power <= number) power <<= 1;
    return number > 1 ? power >> 1 : 1;
}
