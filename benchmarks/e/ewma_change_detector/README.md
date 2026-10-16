# EWMA change detector

The pinned Java class is an EWMA control chart, not a plain EMA filter or an outlier filter. It smooths samples around a target, compares the statistic with a warm-up-dependent sigma band, emits upward/downward alarms, and resets its average to the target after every alarm.

This portable fixed-parameter profile uses target 0, standard deviation 1, alpha 1/2, and width 1. Inputs are `[sample_count, samples...]`, with 0–15 integer samples in [-8, 8]. For each sample, maintain an exact numerator `d` and exponent `n` such that the EWMA statistic is `d / 2^n`; update `n += 1` and `d += sample * 2^(n-1)`. The squared control-limit comparison is exact: alarm iff `3*d*d > 4^n - 1`. Equality does not alarm. An alarm emits 1 for upward or 2 for downward, then resets `d` and `n` to zero. No alarm emits 0.

The result packs the signal trace in base 4, left to right (`packed = packed*4 + signal`); the input length determines the number of signals, including leading zeros. Invalid inputs return -1. The bounds keep all intermediate values within signed 64-bit range and encode at most 15 two-bit signals in a nonnegative signed 64-bit result.

This is distinct from the repository EMA filter, which returns smoothed samples without a threshold, and from Hampel/IQR filters, which compare local samples against robust statistics. The source's general target, sigma, alpha, and width parameters are fixed here to expose one deterministic portable detector profile.

## Pinned source

[TheAlgorithms/Java `EwmaChangeDetector.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/streaming/EwmaChangeDetector.java), commit `e43ec3897e48f23843972d02cd05a5bb1b6864a2`.
