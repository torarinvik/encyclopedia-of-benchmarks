module lucky_number;

const long MAX_INPUT = 1000000L;

// Preserve the pinned Java rank loop, including counter += 1 each round.
fn long lucky_number(long number) @export("lucky_number") {
    if (number < 1L || number > MAX_INPUT) return -1L;
    long counter = 2L;
    long position = number;
    while (counter <= position) {
        if (position % counter == 0L) return 0L;
        position -= position / counter;
        counter++;
    }
    return 1L;
}
