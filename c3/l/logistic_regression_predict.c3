module logistic_regression_predict;

long logistic_regression_predict(long* values, usz length) @export("logistic_regression_predict") {
    if (values == null || length < 2 || length > 2051) return -1;
    long rows = values[0], features = values[1];
    if (rows < 1 || rows > 63 || features < 1 || features > 32) return -1;
    usz row_count = (usz)rows, feature_count = (usz)features;
    if (length != 2 + row_count * feature_count + feature_count) return -1;
    usz theta_offset = 2 + row_count * feature_count;
    for (usz i = 0; i < row_count * feature_count + feature_count; i++) {
        long value = values[2 + i];
        if (value < -1000 || value > 1000) return -1;
    }
    ulong mask = 0;
    for (usz row = 0; row < row_count; row++) {
        long score = 0;
        for (usz feature = 0; feature < feature_count; feature++)
            score += values[2 + row * feature_count + feature] * values[theta_offset + feature];
        if (score >= 0) mask |= 1u64 << row;
    }
    return (long)mask;
}
