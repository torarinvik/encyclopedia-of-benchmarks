# Equal-loudness filter (fixed profile)

This benchmark captures one deterministic fixed-point profile of the pinned Python `EqualLoudnessFilter`: its order-10 Yule–Walker filter cascaded with the 150 Hz Butterworth high-pass, at a fixed 44,100 Hz sample rate. It is distinct from the coefficient-design benchmark `butterworth_filter` and from the general IIR recurrence benchmark `iir_filter`.

The source designs its first-stage coefficients at construction time using the pinned loudness-curve data, interpolation, FFTs, least-squares solves, and polynomial root stabilization. This contract fixes the resulting coefficient set after rounding each coefficient to signed Q30 (nearest, ties away from zero). The high-pass stage coefficients are fixed the same way. This is a normalized fixed-coefficient profile; it avoids runtime numerical-library differences in the source's coefficient-design step. The coefficients were generated from the pinned source with NumPy 2.0.2 and SciPy 1.13.1, then quantized as specified; the contract uses the listed integer constants directly.

Input is `[sample_count, sample_0, ...]`, with 0–32 signed samples scaled by 1,000,000 and bounded to ±1,000,000. Both filter stages start with zero histories for each call. Each stage uses the source recurrence and coefficient order; products and accumulations use signed 64-bit integers, and division by `a0` truncates toward zero. Output is the final filtered sample in the same scale. Empty traces return 0; malformed inputs return -1.

The fixed coefficients are `a=[1073741824,-3875279605,7242592440,-9849938776,11019995787,-10310050823,8022431451,-5130046574,2558322377,-874363774,153873500]`, `b=[60930872,-44894685,-5549718,-9621322,-7681698,30506759,-32060412,22380311,-4826655,8028337,-4488672]` for the Yule–Walker stage, and `a=[1089966811,-2146993250,1057516837]`, `b=[1073619225,-2147238449,1073619225]` for the high-pass stage.

## Pinned sources

- [EqualLoudnessFilter](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/audio_filters/equal_loudness_filter.py)
- [IIRFilter recurrence](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/audio_filters/iir_filter.py)
- [Butterworth high-pass coefficients](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/audio_filters/butterworth_filter.py)
- [Loudness contour data](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/audio_filters/loudness_curve.json)
