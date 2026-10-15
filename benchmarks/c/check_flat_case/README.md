# Check Flat Case

Ports the predicate from the pinned [TheAlgorithms/JavaScript implementation](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/String/CheckFlatCase.js), which applies the regular expression `^[a-z]*$`.

The `i64_array_scalar` ABI represents the string as ASCII code values. Inputs may contain zero through 4,096 printable ASCII values (32..126). The result is 1 when every value is a lowercase ASCII letter, and 0 otherwise. Empty input returns 1, matching the source regex. Values outside the printable range or inputs longer than 4,096 return -2. Printable ASCII excludes line terminators, so JavaScript's special `$` match before a final newline is outside the benchmark domain.

The predicate takes O(n) time and O(1) extra space.
