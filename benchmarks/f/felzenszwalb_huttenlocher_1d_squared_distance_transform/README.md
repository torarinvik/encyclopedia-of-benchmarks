# Felzenszwalb–Huttenlocher 1D squared distance transform

For a bounded sampled function `f[0..N)`, compute
`D[x] = min_i ((x-i)^2 + f[i])` for every integer `x` in the same domain.
The result also includes the least site index attaining each minimum. The ABI
is `i64_array_bytes_output`; input is `[N,f0,...,f(N-1)]`, where
`1<=N<=128` and each cost is in `[0,1,000,000]`. Output is the interleaved
little-endian i64 sequence `[D[0],argmin[0],...,D[N-1],argmin[N-1]]`, at most
2,048 bytes.

Each site defines a parabola `(x-i)^2+f[i]`. The implementation inserts
parabolas in increasing site order into their lower envelope. For current
site `p` and incoming `q>p`, the first integer coordinate where `q` is
strictly better is
`floor((f[q]+q^2-f[p]-p^2)/(2*(q-p)))+1`. Integer floor division makes
crossings exact; equality stays with the earlier, lower-index site. If a new
crossing is no later than the previous site's start coordinate, that site is
removed from the envelope. A final left-to-right scan emits each active
parabola's cost and site index. Each site is inserted and removed at most
once, giving O(N) time and O(N) workspace. The cost and coordinate bounds
keep outputs below 1,016,130 and all arithmetic within signed 64-bit range.

This is the one-dimensional sampled-function lower envelope in Felzenszwalb
and Huttenlocher's *Distance Transforms of Sampled Functions*, Cornell
TR2004-1963. The primary reference follows the integer lower-envelope
construction. The independent reference directly checks every site at every
coordinate and minimizes `(cost,index)`. The local `infinite_knight_distance`
package uses a discrete chess-knight metric and is a different method.

The package contains clean-room C, C3, C++, Elisa, Mojo, Nim, Odin, Rust, V,
and Zig ports, a bounded workload, references, provenance/rights, and static
inventory artifacts. See [RIGHTS.md](RIGHTS.md). No upstream code, prose, or
fixtures are reused.

Malformed or null input returns `-1`. After complete input validation, null
or undersized output returns `-2` without writes. Output capacity is checked
before the envelope is built or any output bytes are written.
