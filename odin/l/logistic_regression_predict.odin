package logistic_regression_predict

import "core:c"

@(export)
logistic_regression_predict :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
    if values == nil || length < 2 || length > 2051 do return -1
    rows, features := values[0], values[1]
    if rows < 1 || rows > 63 || features < 1 || features > 32 do return -1
    row_count, feature_count := c.size_t(rows), c.size_t(features)
    if length != 2 + row_count * feature_count + feature_count do return -1
    theta_offset := 2 + row_count * feature_count
    for i: c.size_t = 0; i < row_count * feature_count + feature_count; i += 1 {
        value := values[2 + i]
        if value < -1000 || value > 1000 do return -1
    }
    mask: u64 = 0
    for row: c.size_t = 0; row < row_count; row += 1 {
        score: i64 = 0
        for feature: c.size_t = 0; feature < feature_count; feature += 1 {
            score += values[2 + row * feature_count + feature] * values[theta_offset + feature]
        }
        if score >= 0 do mask |= u64(1) << u64(row)
    }
    return i64(mask)
}
