module matchstick_triangle_sequence;

fn long matchstick_triangle_sequence(long n) @export("matchstick_triangle_sequence")
{
    if (n < 0 || n > 1000000) return -1;
    return (n * (n + 2) * (2 * n + 1)) / 8;
}
