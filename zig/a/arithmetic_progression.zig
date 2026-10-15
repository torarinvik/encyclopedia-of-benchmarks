/// Sum an inclusive arithmetic progression from packed [from, to, step].
export fn arithmetic_progression(values: [*]const i64, length: usize) i64 {
    if (length != 3) return -1;
    const from = values[0];
    const to = values[1];
    const step = values[2];
    if (from < -1_000_000 or from > 1_000_000 or to < -1_000_000 or to > 1_000_000)
        return -1;
    if (step < -1_000_000 or step > 1_000_000 or step == 0) return -1;
    if ((from < to and step < 0) or (from > to and step > 0)) return -1;
    const count = @divTrunc(to - from, step);
    const last = from + count * step;
    return @divTrunc((count + 1) * (from + last), 2);
}
