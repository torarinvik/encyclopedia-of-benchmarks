extern "C" double square_root_with_babylonian_method(double input) noexcept
{
    if (!(input >= 1.0 && input <= 1000000.0)) return -1.0;
    const float num = static_cast<float>(input);
    float a = num;
    float b = 1.0f;
    constexpr double epsilon = 0.000001;
    while (static_cast<double>(a - b) > epsilon) {
        a = (a + b) / 2.0f;
        b = num / a;
    }
    return static_cast<double>(a);
}
