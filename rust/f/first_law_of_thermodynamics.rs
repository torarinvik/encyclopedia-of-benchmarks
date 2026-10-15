/// Numeric first-law operations over a bounded integer-valued domain.
#[no_mangle]
pub extern "C" fn first_law_of_thermodynamics(operation: f64, a: f64, b: f64) -> f64 {
    if !operation.is_finite() || !a.is_finite() || !b.is_finite()
        || !(0.0..=2.0).contains(&operation) || operation.fract() != 0.0
        || !(-1_000_000.0..=1_000_000.0).contains(&a)
        || !(-1_000_000.0..=1_000_000.0).contains(&b)
        || a.fract() != 0.0 || b.fract() != 0.0
    { return -1e300; }
    if operation == 0.0 { return a - b; }
    if operation == 1.0 { return a + b; }
    a - b
}
