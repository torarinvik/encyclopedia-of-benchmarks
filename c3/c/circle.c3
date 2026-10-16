module circle;

const double INVALID_RESULT = -1.0e300;
const double PI = 3.14159265358979323846;

fn double circle(double radius, double operation) @export("circle") {
    if (!(radius >= -1000000.0 && radius <= 1000000.0 &&
          (operation == 0.0 || operation == 1.0))) return INVALID_RESULT;
    if (operation == 0.0) return radius * 2.0 * PI;
    return radius * radius * PI;
}
