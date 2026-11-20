# Tanh–sinh double-exponential quadrature

This package measures a bounded Takahasi–Mori double-exponential quadrature rule. The primary source is Takahasi and Mori, “Double Exponential Formulas for Numerical Integration,” *Publications of the Research Institute for Mathematical Sciences* 9(3), 1974, pp. 721–741, [DOI 10.2977/PRIMS/1195192451](https://doi.org/10.2977/prims/1195192451). The score-24 RosettaCodeData title was used only to discover this algorithm family; this package defines its own workload and ports.

## Contract

The ABI is `float64_slice_io`. Input is exactly `[function_id,p]`, with integer-valued finite binary64 entries, `function_id ∈ {0,1,2,3}` and `p ∈ {2,3,4}`. The fixed interval is `[-1,1]`. The four callbacks are `1`, `x²`, `1/sqrt(1-x²)`, and `1/sqrt(1-x)`, respectively. Their exact integrals are `2`, `2/3`, `π`, and `2√2`.

For `h=2^-p`, `K=3·2^p`, and `j=-K,…,K`, the primary evaluates the transformed trapezoid

```text
t = j*h
u = (π/2)*sinh(t)
x = tanh(u)
I ≈ h * Σ f(x) * (π/2)*cosh(t)/cosh(u)^2
```

It uses the equivalent stable expressions `q=exp(-2*abs(u))`, `x=sign(u)*(1-q)/(1+q)`, and `sech(u)^2=4q/(1+q)^2`. For the endpoint-singular callbacks, the denominators are evaluated from these identities without subtracting nearly equal values. The loop visits `j` in ascending order, and each binary64 operation follows the sequence documented in `workload.json`; ports must not use fast-math reassociation.

`|t|≤3`, `|u|<16`, and the exponentials, Jacobian, and callback products remain finite in the accepted domain. There is no overflow or non-finite fallback for a valid input. The sum uses 25 to 97 transformed samples; the primary runs in `O(2^p)` time with `O(1)` internal scratch. The independent reference returns the four exact integrals directly, so it checks accuracy without reproducing the transformed sum. The benchmark's absolute comparison tolerance is `1e-5` and relative tolerance is `1e-12`; this bounded profile measures the stated finite truncation, not an unbounded precision guarantee.

Valid input length is 2 words; the parser accepts up to 3 words to pin a trailing-word error. Success writes one float64 and returns `1`. Malformed or null input returns `-1`; valid input with a null output or capacity below one returns `-2`, with no writes on errors. Input validation takes precedence over output validation. The maximum output is one element / 8 bytes. Workspace metadata accounts for the caller output; implementations need only constant internal scratch.

See [`workload.json`](workload.json), [`RIGHTS.md`](RIGHTS.md), the [finite-sum reference](primary_oracle.py), the [analytic reference](independent_oracle.py), and the package-local [`check_inventory.py`](check_inventory.py) / [`verify_workload.py`](verify_workload.py). They are provided for static review and have not been run.

## Language ports

| Language | Source |
|---|---|
| C | [`c/t/tanh_sinh_double_exponential_quadrature.c`](../../../c/t/tanh_sinh_double_exponential_quadrature.c) |
| C3 | [`c3/t/tanh_sinh_double_exponential_quadrature.c3`](../../../c3/t/tanh_sinh_double_exponential_quadrature.c3) |
| C++ | [`cpp/t/tanh_sinh_double_exponential_quadrature.cpp`](../../../cpp/t/tanh_sinh_double_exponential_quadrature.cpp) |
| Elisa | [`elisa/t/tanh_sinh_double_exponential_quadrature.elisa`](../../../elisa/t/tanh_sinh_double_exponential_quadrature.elisa) |
| Mojo | [`mojo/t/tanh_sinh_double_exponential_quadrature.mojo`](../../../mojo/t/tanh_sinh_double_exponential_quadrature.mojo) |
| Nim | [`nim/t/tanh_sinh_double_exponential_quadrature.nim`](../../../nim/t/tanh_sinh_double_exponential_quadrature.nim) |
| Odin | [`odin/t/tanh_sinh_double_exponential_quadrature.odin`](../../../odin/t/tanh_sinh_double_exponential_quadrature.odin) |
| Rust | [`rust/t/tanh_sinh_double_exponential_quadrature.rs`](../../../rust/t/tanh_sinh_double_exponential_quadrature.rs) |
| V | [`v/t/tanh_sinh_double_exponential_quadrature.v`](../../../v/t/tanh_sinh_double_exponential_quadrature.v) |
| Zig | [`zig/t/tanh_sinh_double_exponential_quadrature.zig`](../../../zig/t/tanh_sinh_double_exponential_quadrature.zig) |
