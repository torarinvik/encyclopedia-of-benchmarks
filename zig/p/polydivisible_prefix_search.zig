/// Count a bounded prefix tree of positive polydivisible numbers.
fn extendPrefix(prefix: i64, digits: i64, base: i64, maxDigits: i64) i64 {
    var count: i64 = 1;
    if (digits == maxDigits) return count;
    const nextLength = digits + 1;
    var digit: i64 = 0;
    while (digit < base) : (digit += 1) {
        const candidate = prefix * base + digit;
        if (@mod(candidate, nextLength) == 0)
            count += extendPrefix(candidate, nextLength, base, maxDigits);
    }
    return count;
}

export fn polydivisible_prefix_search(input_opt: ?[*]const i64, length: usize) i64 {
    if (input_opt == null or length != 2) return -1;
    const input = input_opt.?;
    const base = input[0];
    const maxDigits = input[1];
    if (base < 2 or base > 10 or maxDigits < 1 or maxDigits > 6) return -1;
    var count: i64 = 0;
    var firstDigit: i64 = 1;
    while (firstDigit < base) : (firstDigit += 1)
        count += extendPrefix(firstDigit, 1, base, maxDigits);
    return count;
}
