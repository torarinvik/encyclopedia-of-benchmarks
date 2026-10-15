extern "C" double pi_nilakantha(double input) noexcept
{
    if (!(input >= 0.0 && input <= 500.0 && input == static_cast<double>(static_cast<int>(input)))) return -1.0;
    const int iterations = static_cast<int>(input);
    double pi = 3.0;
    int div_counter = 2;
    for (int i = 0; i < iterations; ++i) {
        const double term = 4.0 / (div_counter * (div_counter + 1) * (div_counter + 2));
        if (i % 2 == 0) pi = pi + term;
        else pi = pi - term;
        div_counter += 2;
    }
    return pi;
}
