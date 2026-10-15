module time_and_half_pay;

fn double time_and_half_pay(double hours_worked, double pay_rate, double threshold_hours) @export("time_and_half_pay") {
    if (!(hours_worked >= 0.0 && hours_worked <= 1000.0 && pay_rate >= 0.0 && pay_rate <= 1000.0 && threshold_hours >= 0.0 && threshold_hours <= 1000.0)) return -1e300;
    double normal_pay = hours_worked * pay_rate;
    double over_time = hours_worked - threshold_hours;
    if (over_time < 0.0) over_time = 0.0;
    double over_time_pay = over_time * pay_rate / 2.0;
    return normal_pay + over_time_pay;
}
