/// Pack a bounded prefix of OEIS A086747 using a zero-run parity automaton.
fn baumSweetTerm(number: i64) i64 {
    if (number == 0) return 0;
    var mask: i64 = 1;
    while (mask <= @divTrunc(number, 2)) : (mask *= 2) {}
    var odd_zero_run = false;
    while (mask > 0) : (mask = @divTrunc(mask, 2)) {
        if ((number & mask) != 0) {
            if (odd_zero_run) return 0;
            odd_zero_run = false;
        } else {
            odd_zero_run = !odd_zero_run;
        }
    }
    return if (odd_zero_run) 0 else 1;
}

export fn baum_sweet_sequence(input_opt: ?[*]const i64, length: usize) i64 {
    if (input_opt == null or length != 1) return -1;
    const input = input_opt.?;
    const count = input[0];
    if (count < 0 or count > 63) return -1;
    var packed: i64 = 0;
    var bit: i64 = 1;
    var index: i64 = 0;
    while (index < count) : (index += 1) {
        if (baumSweetTerm(index) != 0) packed += bit;
        if (index + 1 < count) bit *= 2;
    }
    return packed;
}
