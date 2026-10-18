# Linear Discriminant Analysis

This benchmark covers the pinned Python source's deterministic scalar classifier pipeline. The source works with one scalar feature per sample and pools within-class variance into one scalar. This package keeps that model shape and does not claim general multivariate LDA.

## Input and output

The ABI is `float64_slice_io`. Input is `[class_count, count_0, ..., count_(K-1), class-major samples...]`. `class_count` is an exact integer in 2..4. Each class count is an exact integer in 2..6, and the total sample count `N` is at most 16. Samples are finite exact integers in [-32, 32]. Each class's sample mean must be integral. The packed input must contain exactly `1 + K + N` values.

The adapter computes the class means and priors, then the pooled within-class variance. The variance must be positive. It scores each training sample using the source expression, in this order:

```text
mean[k] = sum(class_samples[k]) / count[k]
prior[k] = count[k] / N
variance = 1.0 / (N - K) * sum((sample - mean[class]) ** 2)
score[k] = x * (mean[k] / variance)
           - (mean[k] ** 2 / (2 * variance))
           + log(prior[k])
```

Means and probabilities follow the source's class order. The variance sum walks classes and samples in input order. Predictions use the first class with the maximum score, matching `list.index(max(scores))`. A deterministic adapter guard rejects an input with any sample whose best score is less than `1e-8` above the runner-up; this avoids platform `log` differences changing a near-boundary class prediction. Output is the predicted zero-based class id for each training sample, in class-major input order. Results are exact integer-valued floats, so output comparison tolerance is zero.

Malformed input, nonpositive pooled variance, or a score margin below `1e-8` returns `-1`. A null output pointer or capacity below `N` returns `-2` after input and prediction validation. Errors leave output untouched.

## Source mapping

The pinned source is [TheAlgorithms/Python `linear_discriminant_analysis.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/machine_learning/linear_discriminant_analysis.py), commit `e1a2a8b016001309a73d5fec4818c35cca139795`. The benchmark preserves its `calculate_mean`, `calculate_probabilities`, `calculate_variance`, and `predict_y_values` operations. It supplies deterministic samples directly and predicts on those same grouped samples, as `main` does. It excludes the random Gaussian sample generator, interactive prompts/restart loop, and accuracy display.

## Workload and oracle

- Workload: [`workload.json`](workload.json)
- Independent oracle: [`benchmarks/linear_discriminant_analysis_oracle.py`](../../linear_discriminant_analysis_oracle.py)
