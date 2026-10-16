# NYSIIS encoder

Encodes one bounded name using the NYSIIS phonetic-key rules from the pinned C# source. The benchmark ABI is `i64_array_bytes_output`: input is `[length, ASCII letters...]`; output is the raw uppercase key bytes without a terminator.

The workload accepts 1–64 ASCII letters, case-insensitively. It excludes spaces, punctuation, Unicode, and culture-sensitive casing. The ports preserve the source rule ordering: initial prefix and suffix rewrites, sequential character rewrites, adjacent duplicate removal, then terminal cleanup. Invalid input returns `-1`; insufficient output capacity returns `-2`.

Cases cover the source examples and the prefix, suffix, and character rewrite families. `nysiis_encoder_oracle.py` is the runtime expected-output oracle used by the byte-output runner.
