# Maximum matching word segmentation

Apply left-to-right MaxMatch to a bounded lowercase ASCII text and an ordered dictionary. At each position, choose the longest dictionary word that matches the remaining text. Equal-length duplicate matches select the earliest dictionary entry. If nothing matches, emit one unmatched-character token and advance exactly one character; the method never backtracks to improve later coverage.

## Contract

- Input is a signed-i64 array `[text_length, dictionary_count, text_codes..., (word_length, word_codes...)*]`.
- Text length is 0 through 64; dictionary count is 0 through 16; each dictionary word is 1 through 8 lowercase ASCII letters. Letters are encoded as integer codes 97 through 122. Dictionary order is significant for duplicate-word ties. Empty words are invalid.
- The exact input length is `2 + text_length + sum(1 + word_length)`; the maximum valid length is 210 i64 values. Up to 211 values may be parsed to classify an extra trailing value as malformed.
- Output is raw bytes: one byte for the token count, followed by one byte per token. A matched dictionary entry emits its one-based input position (`1..dictionary_count`); an unmatched character emits `0`. Since every match consumes a nonempty word, there are at most 64 tokens and output is at most 65 bytes. The source text and dictionary plus these token IDs reconstruct the segmentation deterministically. Empty text emits the one-byte record `00`.
- Invalid input returns `-1`. Null output or capacity below the required byte count returns `-2`; errors write no bytes. Valid calls return the number of bytes written.
- The bounded scan uses `O(text_length * dictionary_count * max_word_length)` character comparisons and at most 320 bytes of fixed scratch on a 64-bit target: two 16-element `size_t` tables (256 bytes) and a 64-byte token array. It does not modify the input.

## Algorithm and distinction

The primary ports scan dictionary entries at each current position, retaining a candidate only when it is strictly longer than the current best; this preserves the first dictionary index on ties. A miss emits the unmatched marker and advances one character. This is a greedy maximum-matching tokenizer, not a global search for a complete or minimum-token segmentation. [`word_break`](../../w/word_break/README.md) uses dynamic programming to decide whether some full segmentation exists. [`tokenize_string`](../../t/tokenize_string/README.md) splits at explicit delimiter characters and preserves empty fields; it does not consult a lexicon or choose longest prefixes.

## Workload and references

[`workload.json`](workload.json) covers empty text, a greedy choice that prevents a later dictionary cover, overlapping prefixes, duplicate-word tie handling, unmatched characters before a later match, invalid packing, null output, and short output capacity. The [primary reference](primary_oracle.py) checks each dictionary word directly at every position. The independent [trie reference](independent_oracle.py) follows text through a prefix tree and remembers the last terminal word.

## Sources and rights

- Codewars’ [Optimization collection](https://www.codewars.com/collections/optimization-4) is used only to discover the title “Word Segmentation: MaxMatch”; no kata page, statement, examples, tests, submissions, or solutions were used.
- Sproat, Shih, Gale, and Chang, [“A Stochastic Finite-State Word-Segmentation Algorithm for Chinese”](https://aclanthology.org/J96-3004/), *Computational Linguistics* 22(3), 1996, describes maximum matching as repeatedly choosing the longest dictionary word from the current left or right edge. Sproat and colleagues’ [“A Trainable Rule-Based Algorithm for Word Segmentation”](https://aclanthology.org/P97-1041/), 1997, section 3.2.2 specifies the left-to-right greedy step and the one-character advance when there is no match.

The ports, record format, workload, and references are clean-room work. The academic papers are cited for algorithm semantics only; no source code or benchmark task content was copied.

## Implementations

The ten source paths and support files are listed in [`INVENTORY.md`](INVENTORY.md). Each implementation exports `maximum_matching_word_segmentation` for the `i64_array_bytes_output` ABI.
