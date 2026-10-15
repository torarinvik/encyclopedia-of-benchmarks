module demonetization;

const MAX_AMOUNT = 30;
const MAX_DENOMINATIONS = 4;

fn long ways(long amount, long* input, long count) {
    if (amount < 0 || count < 0) return 0;
    if (amount == 0) return 1;
    if (count == 0) return 0;
    long denomination = input[count + 1];
    return ways(amount, input, count - 1) + ways(amount - denomination, input, count);
}

// Count denomination combinations with the source's recursive recurrence.
fn long demonetization(long* input, usz length) @export("demonetization") {
    if (input == null || length < 2 || length > MAX_DENOMINATIONS + 2) return -1;
    long amount = input[0];
    long count = input[1];
    if (amount < -MAX_AMOUNT || amount > MAX_AMOUNT || count < 0 || count > MAX_DENOMINATIONS
        || length != (usz)(count + 2)) return -1;
    for (usz index = 0; index < (usz)count; index++)
        if (input[index + 2] < 1 || input[index + 2] > MAX_AMOUNT) return -1;
    return ways(amount, input, count);
}
