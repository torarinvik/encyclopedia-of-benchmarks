/// Time and a half pay following the pinned Python calculation order.
#[no_mangle]
pub extern "C" fn time_and_half_pay(hours_worked: f64, pay_rate: f64, threshold_hours: f64) -> f64 {
    if !(hours_worked >= 0.0 && hours_worked <= 1000.0 && pay_rate >= 0.0 && pay_rate <= 1000.0 && threshold_hours >= 0.0 && threshold_hours <= 1000.0) {
        return -1e300;
    }
    let normal_pay = hours_worked * pay_rate;
    let mut over_time = hours_worked - threshold_hours;
    if over_time < 0.0 { over_time = 0.0; }
    let over_time_pay = over_time * pay_rate / 2.0;
    normal_pay + over_time_pay
}
