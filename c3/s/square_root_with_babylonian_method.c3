module square_root_with_babylonian_method;

fn double square_root_with_babylonian_method(double input) @export("square_root_with_babylonian_method")
{
    if (!(input >= 1.0 && input <= 1000000.0)) return -1.0;
    float num = (float)input;
    float a = num;
    float b = 1.0f;
    double epsilon = 0.000001;
    while ((double)(a - b) > epsilon) {
        a = (a + b) / 2.0f;
        b = num / a;
    }
    return (double)a;
}
