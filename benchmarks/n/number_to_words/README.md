# Number to words

Converts a bounded decimal value into the title-cased English words used by the pinned Java `NumberToWords` source. The `i64_array_bytes_output` input is `[sign, whole_part, fractional_digit_count, fractional_digits...]`; output is raw ASCII bytes with spaces between words.

The contract covers whole parts from zero through 999,999,999,999,999 and up to six fractional digits. A nonzero fractional remainder is rendered as `Point` followed by one word per supplied digit, preserving trailing zero digits in the scale. An all-zero fractional remainder is omitted, matching the source's `BigDecimal.compareTo` check. Whole-number groups use `Thousand`, `Million`, `Billion`, and `Trillion`; values above the supported trillion group are excluded because the source has no larger scale name.

Negative values begin with `Negative`. Zero is `Zero`. Output uses title case and no hyphens. Invalid input returns `-1`; insufficient output capacity returns `-2`. The runtime expected-output oracle is `number_to_words_oracle.py`.
