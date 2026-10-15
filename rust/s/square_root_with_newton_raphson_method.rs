/// Newton-Raphson square root under the pinned integer input contract.
const INVALID_RESULT: f64 = -1.0e300;
const MAX_INPUT: f64 = 2_147_483_647.0;

#[no_mangle]
pub extern "C" fn square_root_with_newton_raphson_method(input: f64) -> f64 {
    if !input.is_finite() || input < 1.0 || input > MAX_INPUT || input.fract() != 0.0 {
        return INVALID_RESULT;
    }
    let mut guess = input;
    let mut root = 0.5 * (guess + input / guess);
    while (root - guess).abs() > 1e-7 {
        guess = root;
        root = 0.5 * (guess + input / guess);
    }
    root
}
