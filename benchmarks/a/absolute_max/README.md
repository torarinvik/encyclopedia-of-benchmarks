# Absolute maximum

Select the original value with the greatest absolute magnitude. Equal magnitudes prefer the numerically greater value, so a positive value wins a positive/negative tie.

## Contract

- Input is [value_count, value_0, ..., value_n], with 1 through 256 values.
- Values are bounded to [-1,000,000,000, 1,000,000,000].
- Return the signed value with greatest magnitude; equal magnitudes select the greater signed value.
- Malformed, empty, or out-of-range inputs return -1.

This is separate from abs_max, whose sources preserve the first value on a tie. The pinned Java AbsoluteMax implementation uses the signed tie-break described here. The similarly named PHP function returns the ordinary numeric maximum and does not compare magnitudes.

## Workload and verification

The workload covers signed tie orderings, zero, singleton input, magnitude bounds, and malformed arrays. verify_abs_extrema.py checks this contract against a direct sequence oracle in all nine languages.

## Reviewed TheAlgorithms sources

- [Java AbsoluteMax.java](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/maths/AbsoluteMax.java)
- [PHP AbsoluteMax.php](https://github.com/TheAlgorithms/PHP/blob/b8a54469cc36332ef2934101b58d71075ef1d78e/Maths/AbsoluteMax.php) uses ordinary numeric maximum instead of maximum absolute magnitude.

## Implementations

Nine portable implementations use the shared i64-array/scalar ABI and are stored in each language's a folder.
