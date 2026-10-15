module friendly_numbers;

// Preserve the pinned JavaScript FriendlyNumbers divisor-loop behavior.
fn double abundancy_index(ulong number) {
    ulong sum = number;
    for (ulong divisor = 1; divisor * 2 < number; divisor++)
        if (number % divisor == 0) sum += divisor;
    return (double)sum / (double)number;
}

fn long friendly_numbers(ulong first, ulong second) @export("friendly_numbers") {
    if (first == 0 || second == 0 || first == second || first > 1000 || second > 1000) return -1;
    return abundancy_index(first) == abundancy_index(second) ? 1 : 0;
}
