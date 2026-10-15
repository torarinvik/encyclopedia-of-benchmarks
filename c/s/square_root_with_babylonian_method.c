double square_root_with_babylonian_method(double input)
{
    if (!(input >= 1.0 && input <= 1000000.0)) return -1.0f;
    const float num = (float)input;
    float a = num;
    float b = 1.0f;
    const double epsilon = 0.000001;
    while ((double)(a - b) > epsilon) {
        a = (a + b) / 2.0f;
        b = num / a;
    }
    return (double)a;
}
