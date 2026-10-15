const MAX_INPUT: i64 = 1_000_000;

/// Preserve the pinned Java rank loop, including counter += 1 each round.
export fn lucky_number(number: i64) i64 {
    if (number < 1 or number > MAX_INPUT) return -1;
    var counter: i64 = 2;
    var position = number;
    while (counter <= position) : (counter += 1) {
        if (@mod(position, counter) == 0) return 0;
        position -= @divTrunc(position, counter);
    }
    return 1;
}
