# Ones and zeros

This benchmark ports the pinned Ruby `find_max_form` 0/1 dynamic program. Each input pair records the count of zero and one characters in one binary string. The algorithm processes each item once and updates the capacity table in descending zero and one budgets, returning the largest subset size that fits both limits.

Input is `[item_count, zero_budget, one_budget, zero_count_0, one_count_0, ...]`; there are at most 32 items and each budget and item count is 0–32. An empty binary string is represented by `(0,0)`, matching the source recurrence. Invalid input returns `-1`. `ones_and_zeros_oracle.py` supplies the runtime expected result.
