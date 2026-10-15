# Check snake case

This package preserves the pinned JavaScript predicate in `CheckSnakeCase.js`. Despite the source comment describing snake case validation, the implementation tests the unanchored regular expression `/(.*?)_([a-zA-Z])*/`. The `*` allows zero trailing letters, so the predicate returns true exactly when the input contains an underscore.

The `i64_array_scalar` ABI encodes the string as ASCII code values. Inputs contain zero through 4,096 printable ASCII values (32..126). The result is 1 when any value is underscore (`95`) and 0 otherwise. Out-of-range values or lengths return `-2`; an empty input is valid and returns 0. The printable ASCII restriction captures the source's underscore matching behavior without introducing JavaScript's broader Unicode string representation.

This is distinct from the stricter `check_camel_case` predicate and from the camel/snake conversion routines. The related `check_kebab_case` source checks a hyphen pattern and rejects strings containing underscores.

Source: [TheAlgorithms JavaScript `String/CheckSnakeCase.js`](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/String/CheckSnakeCase.js).
