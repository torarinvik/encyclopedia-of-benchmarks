# RSynth three-sine pitch flutter

This package isolates `flutter` from pinned `lac-dcc/Benchmarks` commit `5d7b75df749241efa7a6e6f5be613d3fcc5cce38`, `cBench/office_rsynth/src/nsynth.c`. When enabled, the source builds a slowly varying perturbation from three sine waves and adds its truncated integer delta to the active F0 value. This helper is independent of the natural and impulsive glottal-source sample packages.

Input is `[F0hz10,f0_flutter,time_count]`. Bounds are `F0hz10` 0..20000, flutter 0..100, and time count 0..1,000,000. The source's integer `F0hz10/10` quotient is computed before the double-valued formula. The selected source-compatible fallback PI value is 3.1415927; the returned value is `F0hz10 + trunc(delta_f0)`, with truncation toward zero. The time count is the value observed when `flutter` is called (the source caller increments its global counter first when flutter is enabled).

The profile excludes frame parsing, synthesis state, sample generation, and all dictionary/phone/speech data. The ports are clean-room adaptations. The package-level CMU notice identifies RSynth as public domain while noting that certain dictionaries, including `beep`, have separate restrictions; no such data is included or used. See [LICENSE.txt](LICENSE.txt). No runtime verification is claimed.
