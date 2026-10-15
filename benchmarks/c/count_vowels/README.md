# Count Vowels

Counts ASCII vowels in a string, using the character scan represented by the pinned [JavaScript implementation](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/String/CountVowels.js), [PHP simple implementation](https://github.com/TheAlgorithms/PHP/blob/b8a54469cc36332ef2934101b58d71075ef1d78e/Strings/CountVowels.php), and [Python implementation](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/strings/count_vowels.py).

The `i64_array_scalar` ABI represents the string as a sequence of ASCII code values. Valid input has 1 through 4,096 values, each in 0..127, except comma (44) is excluded, and the one-character string `0` is excluded. The output is the count of ASCII `a`, `e`, `i`, `o`, and `u`, ignoring case. Invalid inputs return -2. The scan takes O(n) time and O(1) extra space.

These bounds keep the three pinned implementations aligned: PHP rejects an empty string and the exact string `0`; JavaScript and Python return zero for those inputs. PHP also has a regex variant whose character class counts commas, so comma is outside this benchmark's domain. The PHP simple scan agrees with the other pinned implementations throughout the supported domain.
