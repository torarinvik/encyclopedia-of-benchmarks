/// In-place exchange sort for the shared sorting contract.
export fn exchange_sort(values: [*]i64, length: usize) void {
    if (length < 2) return;
    const last = length - 1;
    for (0..last) |first| {
        for (first + 1..length) |other| {
            if (values[other] < values[first]) {
                const temporary = values[first];
                values[first] = values[other];
                values[other] = temporary;
            }
        }
    }
}
