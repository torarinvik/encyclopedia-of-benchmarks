# Next smaller element

For each array position, return the nearest strictly smaller value that appears to its left. The pinned Java implementation's behavior is determined by its left-to-right monotonic-stack loop. Despite the candidate name, it does not search to the right.

## Contract

- Input is packed as signed 64-bit integers `[n, values...]`, with exact packing and no trailing values.
- `n` is in `0..=1024`; each value is a signed 32-bit integer.
- For each value, pop prior stack entries while they are greater than or equal to the current value. Return the remaining stack top, or `-1` if the stack is empty, then push the current value.
- Emit one signed 64-bit little-endian output word per input value and return `8*n` bytes. Empty input returns zero bytes.
- Malformed packing or out-of-domain values return `-1`; insufficient output capacity returns `-2`.

Equal values are removed from the stack, so a match must be strictly smaller. The output uses `-1` as the source's per-position “no prior smaller value” marker; it is data inside the encoded output.

## Source and distinction

- [TheAlgorithms/Java `NextSmallerElement.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/stacks/NextSmallerElement.java)

The nearby `next_greater_element` candidate scans in the opposite direction and seeks a strictly greater value. It has no benchmark package in this tree. [`workload.json`](workload.json) covers the pinned Java example, duplicates, negative values, monotone inputs, empty input, and malformed/domain inputs.
