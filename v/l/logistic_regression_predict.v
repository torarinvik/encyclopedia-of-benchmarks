module logistic_regression_predict

@[export: 'logistic_regression_predict']
pub fn logistic_regression_predict(values &i64, length usize) i64 {
    if unsafe { values == nil } || length < 2 || length > 2051 { return -1 }
    rows := unsafe { values[0] }; features := unsafe { values[1] }
    if rows < 1 || rows > 63 || features < 1 || features > 32 { return -1 }
    row_count := usize(rows); feature_count := usize(features)
    if length != 2 + row_count * feature_count + feature_count { return -1 }
    theta_offset := 2 + row_count * feature_count
    for i in 0 .. row_count * feature_count + feature_count {
        value := unsafe { values[2 + i] }
        if value < -1000 || value > 1000 { return -1 }
    }
    mut mask := u64(0)
    for row in 0 .. row_count {
        mut score := i64(0)
        for feature in 0 .. feature_count { score += unsafe { values[2 + row * feature_count + feature] * values[theta_offset + feature] } }
        if score >= 0 { mask |= u64(1) << u64(row) }
    }
    return i64(mask)
}
