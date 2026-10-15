module first_law_of_thermodynamics;

fn double first_law_of_thermodynamics(double operation, double a, double b) @export("first_law_of_thermodynamics") {
    if (operation != operation || a != a || b != b || operation < 0.0 || operation > 2.0 ||
        operation != (double)(long)operation || a < -1000000.0 || a > 1000000.0 ||
        b < -1000000.0 || b > 1000000.0 || a != (double)(long)a || b != (double)(long)b) return -1e300;
    if (operation == 0.0) return a - b;
    if (operation == 1.0) return a + b;
    return a - b;
}
