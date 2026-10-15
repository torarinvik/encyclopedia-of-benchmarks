module arithmetic_progression;

fn long arithmetic_progression(long* values, usz length) @export("arithmetic_progression")
{
    if (values == null || length != 3) return -1;
    long from = values[0], to = values[1], step = values[2];
    if (from < -1000000 || from > 1000000 || to < -1000000 || to > 1000000 ||
        step < -1000000 || step > 1000000 || step == 0) return -1;
    if ((from < to && step < 0) || (from > to && step > 0)) return -1;
    long count = (to - from) / step;
    long last = from + count * step;
    return ((count + 1) * (from + last)) / 2;
}
