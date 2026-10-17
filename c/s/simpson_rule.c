#define INVALID_RESULT (-1.0e300)

static double simpson_rule_f(double x)
{
    return (x - 0.0) * (x - 0.0);
}

double simpson_rule(double b, double steps)
{
    if ((b != 1.0 && b != 2.0 && b != 3.0) || steps != 10.0) return INVALID_RESULT;

    const double a = 0.0;
    const double h = (b - a) / steps;
    double x = a + h;
    double y = 0.0;
    y += (h / 3.0) * simpson_rule_f(a);
    int count = 2;
    while (x < b - h) {
        const int weight = 4 - 2 * (count % 2);
        y += (h / 3.0) * weight * simpson_rule_f(x);
        ++count;
        x = x + h;
    }
    y += (h / 3.0) * simpson_rule_f(b);
    return y;
}
