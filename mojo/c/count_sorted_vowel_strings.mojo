@export("count_sorted_vowel_strings")
fn count_sorted_vowel_strings(n: Int64) abi("C") -> Int64:
    if n < 0 or n > 30000: return -1
    return ((n + 4) * (n + 3) * (n + 2) * (n + 1)) / 24
