/// Preserve the digit-window recurrence used by the pinned C# checker.
export fn keith_number_checker(number: i64) i64 {
    if (number < 2 or number > 1000) return -1;
    const allocator = std.heap.page_allocator;
    const length: usize = @intCast(number);
    const terms = allocator.alloc(i64, length) catch return -1;
    defer allocator.free(terms);
    @memset(terms, 0);

    const original = number;
    var temp = number;
    var digits: usize = 0;
    while (temp != 0) : (digits += 1) temp = @divTrunc(temp, 10);
    temp = number;
    var i = digits;
    while (i > 0) {
        i -= 1;
        terms[i] = @rem(temp, 10);
        temp = @divTrunc(temp, 10);
    }

    var sum: i64 = 0;
    var k = digits;
    while (sum < original) {
        sum = 0;
        var j: usize = 1;
        while (j <= digits) : (j += 1) sum += terms[k - j];
        terms[k] = sum;
        k += 1;
    }
    return if (sum == original) 1 else 0;
}
