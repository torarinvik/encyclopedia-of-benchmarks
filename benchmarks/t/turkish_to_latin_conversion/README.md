# Turkish-to-Latin Conversion

This benchmark ports the pinned Java conversion table. It replaces twelve Turkish letters with their corresponding basic Latin letters and preserves all other Unicode characters. The ports decode UTF-8 scalars explicitly so the same mapping and validation apply in every target language.

## Contract

- Input is `[UTF-8 byte_length, UTF-8 bytes...]`, with 0 through 1,024 payload bytes. The payload must be well-formed UTF-8; malformed sequences and bytes outside `0..255` return `-1`.
- The case-sensitive replacements are `ı→i`, `İ→I`, `ü→u`, `Ü→U`, `ö→o`, `Ö→O`, `ş→s`, `Ş→S`, `ç→c`, `Ç→C`, `ğ→g`, and `Ğ→G`. Every other Unicode scalar is preserved without normalization or case folding.
- Output is the transformed UTF-8 byte sequence. The return value is the output byte length. Insufficient output capacity returns `-2` without writing.
- The implementation takes O(n) time and O(n) private storage for an input of n bytes.

The source is [TheAlgorithms/Java `TurkishToLatinConversion.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/conversions/TurkishToLatinConversion.java). The source's `replaceAll` calls apply one literal BMP character replacement at a time. The local ports implement that table on validated UTF-8 and leave unrelated code points, including supplementary characters and combining marks, unchanged.

`workload.json` covers every replacement, mixed case, embedded NUL, unchanged Unicode, maximum-length input, and malformed UTF-8. The verifier exhaustively checks short strings over replacement and unaffected characters, plus deterministic random, boundary, and capacity cases.
