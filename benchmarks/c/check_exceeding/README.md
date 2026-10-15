# Check Exceeding

Ports the pinned [TheAlgorithms/JavaScript implementation](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/String/CheckExceeding.js). It uppercases the string, removes every character outside ASCII `A`..`Z`, computes the absolute code-point gap for each adjacent pair of different letters, and returns true if those gaps are nondecreasing. Equal adjacent letters contribute no gap. An empty gap list returns true.

The `i64_array_scalar` ABI represents the string as ASCII code values. Inputs may contain zero through 4,096 printable ASCII values (32..126). The result is 1 for true and 0 for false. Values outside the printable range or inputs longer than 4,096 return -2. The printable-ASCII bound preserves the source's case normalization and letter filter without JavaScript-specific Unicode uppercasing behavior.

The implementation takes O(n) time and O(1) extra space by checking each gap as it is produced.
