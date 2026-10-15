/// Repeated-doubling search from the pinned source, bounded to its i32 domain.
export fn find_previous_power_of_two(number: i64) i64 {
    if (number < 0 or number > 2_147_483_647) return -1;
    if (number == 0) return 0;

    var power: i64 = 1;
    while (power <= number) : (power <<= 1) {}
    if (number > 1) return power >> 1;
    return 1;
}
