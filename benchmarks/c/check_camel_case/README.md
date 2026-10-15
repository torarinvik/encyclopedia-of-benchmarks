# Check Camel Case

Ports the predicate from the pinned [TheAlgorithms/JavaScript implementation](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/String/CheckCamelCase.js). The source applies the regular expression `^[a-z][A-Za-z]*$`.

The `i64_array_scalar` ABI represents the string as ASCII code values. Inputs may contain zero through 4,096 printable ASCII values (32..126). The result is 1 when the string is nonempty, starts with a lowercase ASCII letter, and contains only ASCII letters; otherwise it is 0. Values outside the printable range or inputs longer than 4,096 return -2. Empty input is valid and returns 0. Restricting the input to printable ASCII avoids JavaScript's special `$` match immediately before a final line terminator.

The predicate takes O(n) time and O(1) extra space.
