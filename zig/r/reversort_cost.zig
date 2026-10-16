pub export fn reversort_cost(values: [*c]const i64, length: usize) i64 {
    if (length > 256) return -1;
    var working: [256]i64 = @splat(0);
    for (0..length) |index| {
        if (values[index] < -2147483648 or values[index] > 2147483647) return -1;
        working[index] = values[index];
    }
    var cost: i64 = 0;
    for (0..length) |index| {
        if (index + 1 >= length) break;
        var minimum = index;
        for (index + 1..length) |probe| {
            if (working[probe] < working[minimum]) minimum = probe;
        }
        var left = index;
        var right = minimum;
        while (left < right) : ({ left += 1; right -= 1; }) {
            const temporary = working[left];
            working[left] = working[right];
            working[right] = temporary;
        }
        cost += @intCast(minimum - index + 1);
    }
    return cost;
}
