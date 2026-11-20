# Hanging-line largest rectangle

This package computes the largest unit-width rectangle in a bounded histogram
using hanging-line reachability links. It returns the same mathematical result
as `largest_rectangle_histogram`, but uses a distinct timed method: the local
package uses a monotone stack, while this package reuses already-computed
left/right reach boundaries and contains no stack.

## Contract

The ABI is `i64_array_scalar`; the exported symbol is
`hanging_line_largest_rectangle`. Input is a signed 64-bit height array with
length 0 through 64 and each height in `[0, 1,000,000]`. Return the maximum of
`height[i] * width` over contiguous intervals. Empty input returns 0, including
a null pointer with length zero. Length above 64, a null pointer for nonempty
input, or an out-of-range height returns `INT64_MIN`. The maximum valid area is
64,000,000.

## Algorithm

For every bar `i`, keep `left[i]`, the furthest left position whose bars are
all at least `height[i]`. In a left-to-right pass, start at `left[i] = i`. If
the preceding bar is at least as tall, jump directly to the already computed
`left[left[i]-1]`; repeat until the boundary or a shorter bar. A right-to-left
pass symmetrically computes `right[i]`, jumping to `right[right[i]+1]` when the
next bar is at least as tall. The candidate rectangle for `i` has width
`right[i]-left[i]+1`; take the largest area.

The links skip whole reach intervals, so both passes take amortized `O(n)` time
and use `O(n)` auxiliary words. This is not a wrapper around the local
monotone-stack implementation. The primary oracle uses prior-link jumps; the
independent oracle enumerates intervals. Static fixture validation checks both.

## Workload and provenance

[`workload.json`](workload.json) includes link-jump, plateau, monotone, zero,
maximum-bound, and malformed-input cases. The structurally independent
quadratic interval oracle is [`independent_oracle.py`](independent_oracle.py).
The root scalar runner and verifier register the bounded profile.

The method description is from OI Wiki English, [Hanging Line
Method](https://www.timothywang.ca/OI-wiki/misc/hoverline/). It describes
reusing previously computed left/right reaches and gives an amortized linear
bound. OI Wiki identifies the page as CC BY-SA 4.0 with an additional SATA
notice. This package uses the algorithmic idea only: the description and
reference code have not been copied. See [`RIGHTS.md`](RIGHTS.md).

## Implementations

| Language | Source |
|---|---|
| C | [`c/h/hanging_line_largest_rectangle.c`](../../../c/h/hanging_line_largest_rectangle.c) |
| C3 | [`c3/h/hanging_line_largest_rectangle.c3`](../../../c3/h/hanging_line_largest_rectangle.c3) |
| C++ | [`cpp/h/hanging_line_largest_rectangle.cpp`](../../../cpp/h/hanging_line_largest_rectangle.cpp) |
| Elisa | [`elisa/h/hanging_line_largest_rectangle.elisa`](../../../elisa/h/hanging_line_largest_rectangle.elisa) |
| Mojo | [`mojo/h/hanging_line_largest_rectangle.mojo`](../../../mojo/h/hanging_line_largest_rectangle.mojo) |
| Nim | [`nim/h/hanging_line_largest_rectangle.nim`](../../../nim/h/hanging_line_largest_rectangle.nim) |
| Odin | [`odin/h/hanging_line_largest_rectangle.odin`](../../../odin/h/hanging_line_largest_rectangle.odin) |
| Rust | [`rust/h/hanging_line_largest_rectangle.rs`](../../../rust/h/hanging_line_largest_rectangle.rs) |
| V | [`v/h/hanging_line_largest_rectangle.v`](../../../v/h/hanging_line_largest_rectangle.v) |
| Zig | [`zig/h/hanging_line_largest_rectangle.zig`](../../../zig/h/hanging_line_largest_rectangle.zig) |
