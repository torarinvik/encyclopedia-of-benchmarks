module pi_nilakantha;

fn double pi_nilakantha(double input) @export("pi_nilakantha")
{
    if (!(input >= 0.0 && input <= 500.0 && input == (double)(int)input)) return -1.0;
    int iterations = (int)input;
    double pi = 3.0;
    int divCounter = 2;
    for (int i = 0; i < iterations; i++) {
        double term = 4.0 / (divCounter * (divCounter + 1) * (divCounter + 2));
        if (i % 2 == 0) pi = pi + term;
        else pi = pi - term;
        divCounter += 2;
    }
    return pi;
}
