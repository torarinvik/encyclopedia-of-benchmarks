module tribonacci_numbers_sequence;

// Zero-based Tribonacci sequence with source seeds 1, 1, 1.
fn long tribonacci_numbers_sequence(long index) @export("tribonacci_numbers_sequence")
{
    if (index < 0 || index > 60) return -1;
    if (index < 3) return 1;

    long first = 1;
    long second = 1;
    long third = 1;
    for (long i = 3; i <= index; i++) {
        long next = first + second + third;
        first = second;
        second = third;
        third = next;
    }
    return third;
}
