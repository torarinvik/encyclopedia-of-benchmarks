# Multinomial Naive Bayes classifier

Fit the pinned Java multinomial Naive Bayes model one or two times, then predict a bounded batch of count vectors using the final fit.

## Contract

- Input is a packed signed-64-bit integer array: `[fit_count, (train_rows, feature_width, labels[train_rows], feature_counts[train_rows * feature_width])*, prediction_count, prediction_width, prediction_counts[prediction_count * prediction_width]]`.
- `fit_count` is 1 or 2. Every fit has 1–16 rows and 1–8 features. Labels are 0–7; feature counts are 0–100. Prediction batches have 1–8 rows, use the last fit's width, and contain counts in the same range. All records must be present with no trailing words.
- Alpha is fixed at the source default, 1.0; custom alpha values are outside this input domain. Each fit replaces prior fitted state. For each class, the model computes `log(class_rows / training_rows)` and per-feature `log((class_feature_sum + 1) / (class_feature_total + feature_width))`. A prediction adds the log prior to each `sample[j] * log_likelihood[j]` in feature order and returns the highest-scoring class.
- Predictions are accepted only when the highest score is separated from the next-highest score by at least `1e-8`; tied or closer scores are outside the portable contract because the Java source iterates `HashMap` entries.
- Output is the prediction count followed by predicted class labels, encoded as little-endian signed 64-bit words. The maximum result is 9 words (72 bytes).
- Malformed shapes, out-of-domain counts/labels, and ambiguous predictions return `-1`. A null output buffer or insufficient capacity returns `-2` after input and prediction validation. Errors write no bytes.

The fixed-width encoding ensures rectangular rows. A two-fit trace covers the source's model reset behavior; only predictions from the final fit are returned. The batch API is used for every prediction fixture.

- [TheAlgorithms/Java pinned `MultinomialNaiveBayesClassifier.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/machinelearning/MultinomialNaiveBayesClassifier.java)
