# Bivariate formal power-series reciprocal

This draft computes the reciprocal of a two-variable formal series truncated
independently in both exponents. It differs from
[`inv_of_formal_power_series`](../inv_of_formal_power_series/README.md), which
has one exponent, and [`multivariate_convolution`](../../m/multivariate_convolution/README.md),
which multiplies supplied series without inversion.

The `i64_array_bytes_output` input is `[rows,columns,coefficients...]`, with
`1 <= rows,columns <= 8` and row-major coefficients in `[0,998244352]`.
The constant coefficient must be nonzero. Output is the same number of
little-endian i64 residues in row-major order, satisfying `f*g=1` modulo
`(x^rows,y^columns)` over `F_998244353`. Invalid or null input returns `-1`;
null or short output returns `-2` without writes. The maximum input length is
66 words and the maximum output is 512 bytes.

The draft solves coefficient relations in row-major order, with a modular
inverse for the constant term. Its time is O(rows² columns² + log P), with
O(rows columns) storage. The independent reference uses Newton refinement and
truncated two-dimensional multiplication.

The [Library Checker catalog entry](https://judge.yosupo.jp/problem/inv_of_formal_power_series_2d)
provides the operation idea; its problem repository declares Apache-2.0. The
local contract, code, and reference are independently written without copying
task text, code, or fixtures.

Status: all ten language drafts, an independent reference, a workload, and
byte-output suite registration are present. Verifier source specifies all
bounded rectangular dimensions, maximum framing, invalid input, and buffer
boundaries. Nothing has been compiled or run.
