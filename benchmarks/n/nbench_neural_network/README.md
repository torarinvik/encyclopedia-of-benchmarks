# NBench neural-network back-propagation kernel

This package is a deterministic bounded kernel variant derived from NBench BYTEmark's back-propagation network. It is not an official NBench score and does not include the timing driver.

## Fixed profile

The network keeps the source's 35 input, 8 middle-neuron, and 8 output-neuron dimensions. It uses the single 5×7 `O` pattern shown in the source comments and the eight target bits `01001111`. Initial weights are fixed explicitly by the formulas `mid[n][w] = (((17*n + 7*w) mod 101) - 50) / 1000` and `out[n][w] = (((13*n + 5*w) mod 71) - 35) / 1000`; this replaces source random initialization. Input is exactly `[passes]`, with `passes` in `1..=8`. Each pass processes the one pattern once.

The kernel preserves source operation order for momentum transfer and zeroing, both calls to `do_mid_forward` in `do_forward_pass`, output forward propagation, output errors, middle-layer errors using pre-update output weights, output weight updates, then middle weight updates. It uses `BETA = 0.09` and `ALPHA = 0.09`. The unbounded train-until-learned loop, convergence/error checks, file parser, random generator, and benchmark timing are omitted; the fixed pass count is the bound.

Output is eleven little-endian signed 64-bit values: `[passes, output_0..output_7, mid_weight_sum, output_weight_sum]`. Activations are from the last forward pass before that pass's weight updates; weight sums are from the resulting post-update weights. The eight activations and two weight sums are truncated after multiplication by 1,000,000. Success returns 88 bytes; invalid input returns `-1`; null or short output returns `-2`; errors leave output untouched.

## Source and notice

The kernel is based on `DoNNetIteration`, `do_mid_forward`, `do_out_forward`, `do_forward_pass`, `do_out_error`, `do_mid_error`, `adjust_out_wts`, `adjust_mid_wts`, and `move_wt_changes` in [`nbench/src/nbench1.c` at nfinit/ansibench commit ef90abd09d7b7bb1f2809f896d6f67fb9724bebe](https://github.com/nfinit/ansibench/blob/ef90abd09d7b7bb1f2809f896d6f67fb9724bebe/nbench/src/nbench1.c), with dimensions and constants from `nbench/include/nbench1.h`. The original network comments credit Maureen Caudill (1988–1991); the BYTEmark source credits Rick Grehan and BYTE Magazine. The exact upstream NBench notice is retained in [`LICENSE`](LICENSE); it is an “as is” notice and disclaimer, not a permissive open-source license. Preserve the notice and attribution when redistributing derived work.

## Workload and oracle

The independent oracle is [`benchmarks/nbench_neural_network_oracle.py`](../../nbench_neural_network_oracle.py). Implementations are provided in C, C++, C3, Elisa, Nim, Odin, Rust, V, and Zig.
