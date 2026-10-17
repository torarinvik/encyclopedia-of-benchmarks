module richest_customer_wealth;

const usz MAX_ROWS = 32;
const usz MAX_COLUMNS = 32;
const long MAX_ROWS_VALUE = 32;
const long MAX_COLUMNS_VALUE = 32;
const usz MAX_INPUT_LENGTH = 2 + MAX_ROWS * MAX_COLUMNS + 1;
const long MAX_AMOUNT = 1000000;

fn long richest_customer_wealth(long* input, usz length) @export("richest_customer_wealth") {
    if (input == null || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    if (input[0] < 1 || input[0] > MAX_ROWS_VALUE || input[1] < 1 || input[1] > MAX_COLUMNS_VALUE) return -1;
    usz rows = (usz)input[0], columns = (usz)input[1];
    if (length != 2 + rows * columns) return -1;
    long richest = 0;
    for (usz row = 0; row < rows; row++) {
        long wealth = 0;
        for (usz column = 0; column < columns; column++) {
            long amount = input[2 + row * columns + column];
            if (amount < 0 || amount > MAX_AMOUNT) return -1;
            wealth += amount;
        }
        if (wealth > richest) richest = wealth;
    }
    return richest;
}
