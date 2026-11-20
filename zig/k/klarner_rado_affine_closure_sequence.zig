export fn klarner_rado_affine_closure_sequence(input: [*c]const i64, length: usize) i64 {
    if (input == null or length < 1 or length > 2) return -1;
    const requested = input[0];
    if (length != 1 or requested < 1 or requested > 64) return -1;

    var terms = [_]i64{0} ** 64;
    terms[0] = 1;
    var count: usize = 1;
    var twice: usize = 0;
    var thrice_plus_two: usize = 0;
    var sixfold_plus_three: usize = 0;
    while (count < @as(usize, @intCast(requested))) {
        const by_two = 2 * terms[twice];
        const by_three = 3 * terms[thrice_plus_two] + 2;
        const by_six = 6 * terms[sixfold_plus_three] + 3;
        const next = @min(by_two, @min(by_three, by_six));
        terms[count] = next;
        count += 1;
        if (by_two == next) twice += 1;
        if (by_three == next) thrice_plus_two += 1;
        if (by_six == next) sixfold_plus_three += 1;
    }
    return terms[@intCast(requested - 1)];
}
