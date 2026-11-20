# Package inventory

- ABI: `i64_array_bytes_output`; symbol: `digital_filter_direct_form_ii_transposed`.
- Input: `[N,L,a0..aL,b0..bL,x0..x(N-1)]`; `N<=32`, `L<=4`, `a0=1`.
- Other coefficients are in `[-1,1]`; samples are in `[-16,16]`.
- Valid/parseable input maxima: 44/45 signed-i64 words.
- Output: one little-endian signed-i64 value per sample; maximum 256 bytes.
- Invalid input returns `-1`; null/short nonempty output returns `-2` without writes.
- Primary: transposed Direct Form II shared delay-state chain.
- Independent reference: direct difference equation over input/output histories.
- Native workspace cap: 256 bytes, excluding caller-owned input/output.
- Ten ports: C, C3, C++, Elisa, Mojo, Nim, Odin, Rust, V, Zig.
- Provenance: RosettaGit task title and Cambridge DSP lecture slides; clean-room work.
