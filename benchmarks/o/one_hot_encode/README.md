# One-hot encode

This package covers the pinned R `oneHotEncode` default behavior for a data frame with one character column. R treats the column as a factor and `model.matrix(~0 + ., data=x)` creates one indicator column per observed level.

The bounded `i64_array_bytes_output` input is `[row_count, category_codes...]`. Each code 0–25 represents the one-character category label A–Z. Output is a row-major matrix of raw bytes 0 or 1, with columns ordered by ascending observed label. The input has 1–32 rows; absent categories do not create columns.

This contract isolates the source's one-column categorical operation from multi-column data-frame handling and R-specific column-name formatting. Invalid input returns `-1`; insufficient output capacity returns `-2`. `one_hot_encode_oracle.py` is the runtime expected-output oracle.
