/// Time and a half pay following the pinned Python calculation order.
export fn time_and_half_pay(hours_worked: f64, pay_rate: f64, threshold_hours: f64) f64 {
    if (!(hours_worked >= 0.0 and hours_worked <= 1000.0 and pay_rate >= 0.0 and pay_rate <= 1000.0 and threshold_hours >= 0.0 and threshold_hours <= 1000.0)) return -1e300;
    const normal_pay = hours_worked * pay_rate;
    var over_time = hours_worked - threshold_hours;
    if (over_time < 0.0) over_time = 0.0;
    const over_time_pay = over_time * pay_rate / 2.0;
    return normal_pay + over_time_pay;
}
