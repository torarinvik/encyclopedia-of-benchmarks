/// Search in ascending order for a full period of distinct residues.
export fn primitive_root(input: ?[*]const i64, length: usize) i64 {
    if (input == null or length != 1) return -1;
    const values = input.?;
    if (values[0] < 2 or values[0] > 127) return -1;
    const modulus: usize = @intCast(values[0]);
    for (1..modulus) |candidate| {
        var seen: [127]bool = @splat(false);
        var power: usize = 1;
        var distinct = true;
        for (0..modulus - 1) |_| {
            if (seen[power]) {
                distinct = false;
                break;
            }
            seen[power] = true;
            power = (power * candidate) % modulus;
        }
        if (distinct) return @intCast(candidate);
    }
    return 0;
}
