# Count substring occurrences

Counts every occurrence of a pattern in a text, including overlapping matches. This follows the pinned JavaScript routine: it calls `indexOf` repeatedly and resumes the next search one code unit after the previous match.

## Contract

- Uses `i64_array_scalar` with packed input `[text_length, pattern_length, text_ascii..., pattern_ascii...]`.
- Text and pattern lengths are each from 0 through 4,096. Every character is encoded as an integer in 0..127, which maps one-to-one to JavaScript UTF-16 code units on this ASCII domain.
- Returns the number of matching positions. An empty pattern returns `text_length + 1`, including one match for empty text. Occurrences may overlap. Invalid lengths, packing, or character codes return `-1`.

Source: [TheAlgorithms JavaScript `String/CountSubstrings.js`](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/String/CountSubstrings.js).

This counts all match positions; string search routines that return a first index, a position list, or only a Boolean answer have different output contracts.
