# Check word occurrence

This benchmark follows TheAlgorithms/JavaScript `checkWordOccurrence` function, which returns a word-to-count object from a string. The pinned function has an unusual flag behavior: when `isCaseSensitive` is true it lowercases the whole string; when false it preserves case. The benchmark preserves that behavior.

## Contract

The `i64_array_bytes_output` ABI packs `[lowercase_flag, n, ascii_bytes...]`. The flag is 0 or 1; `n` is 0..1024 and the packed length must equal `n+2`. Input bytes may be ASCII letters or the ASCII whitespace bytes tab, line feed, vertical tab, form feed, carriage return, and space. With flag 0, token case is preserved. With flag 1, ASCII uppercase letters are converted to lowercase before splitting.

The source splits on runs of `/\s+/`. Repeated whitespace is one separator. Empty fields at the beginning or end are preserved, and an empty input produces one empty token. Each token is counted exactly. The output is a deterministic binary encoding of the returned mapping: a little-endian u32 entry count, followed by entries in first-occurrence order, each encoded as little-endian u32 key length, key bytes, and little-endian u32 count. Alphabetic keys avoid JavaScript's integer-key enumeration rules. To avoid inherited `Object.prototype` property behavior, tokens whose ASCII lowercase form is one of `constructor`, `toString`, `toLocaleString`, `valueOf`, `hasOwnProperty`, `isPrototypeOf`, or `propertyIsEnumerable` are outside the benchmark domain and return `-1`.

Malformed packing, invalid flags, unsupported input bytes, or excluded property names return `-1`. Insufficient output capacity returns `-2`; success returns the encoded byte length. The 1,024-byte input bound keeps counts and output size small and exact.

## Source and distinction

Pinned source: [TheAlgorithms/JavaScript `CheckWordOccurrence.js`](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/String/CheckWordOccurrence.js).

This differs from the Python/F# `word_occurrence` sources, which discard empty fields while splitting whitespace and preserve token case. It also differs from `count_words`, which reports total words and the frequency of one requested word, and `word_count_julia`, which lowercases and regex-extracts word tokens while discarding empty fields.

`workload.json` covers empty input, whitespace boundaries and runs, both flag values, insertion order, invalid flags/bytes/property names, and packed-length errors. The nine ports use the existing `i64_array_bytes_output` ABI.
