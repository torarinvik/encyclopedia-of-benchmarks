# Perplexity loss

This benchmark ports the pinned Python [`perplexity_loss`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/machine_learning/loss_functions.py) method. It selects the predicted probability at each target token, clips it to `[1e-7, 1]`, computes a perplexity for each sentence, and averages those sentence-level values across the batch.

## Contract

The `i64_array_float64_call` ABI receives `[batch, time, vocab, labels[batch*time], probabilities_micro[batch*time*vocab]]`. Dimensions are bounded by `1 <= batch <= 8`, `1 <= time <= 16`, and `2 <= vocab <= 16`. Labels are class IDs in `[0, vocab-1]`. Each probability is a nonnegative integer in `[0, 1,000,000]` divided by `1,000,000`, and every time-step row sums exactly to `1,000,000`. The exact packed length is `3 + batch*time + batch*time*vocab`.

For each sentence, average the natural logs of its clipped target-token probabilities over time, exponentiate the negated mean, then average those perplexities over the batch. Do not exponentiate one pooled token mean. The source checks `label > vocab_size`; this contract restricts labels to IDs strictly below `vocab_size` so every class lookup is defined. Malformed packing, dimensions, labels, or probability rows return `-1e300`. Results use absolute tolerance `1e-10` and relative tolerance `1e-12`.

## Workload

[`workload.json`](workload.json) covers single-token and sequence cases, batch averaging, epsilon clipping, and invalid inputs. The independent oracle is [`perplexity_loss_oracle.py`](../../perplexity_loss_oracle.py).

## Implementations

The nine language ports live in `c/p`, `c3/p`, `cpp/p`, `elisa/p`, `nim/p`, `odin/p`, `rust/p`, `v/p`, and `zig/p`.
