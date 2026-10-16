module cone;

extern fn double sqrt(double value);
const double PI = 3.14159265358979323846;
const double INVALID_RESULT = -1.0e300;

fn double cone(long* values, usz length) @export("cone") {
    if (values == null || length != 3) return INVALID_RESULT;
    long operation = values[0];
    long radius = values[1];
    long height = values[2];
    if ((operation != 0 && operation != 1) || radius < 0 || radius > 1000 ||
        height < 0 || height > 1000) return INVALID_RESULT;
    double radius_value = (double)radius;
    double radius_squared = radius_value * radius_value;
    double base_area = radius_squared * PI;
    if (operation == 0) return (base_area * (double)height * 1.0) / 3.0;
    double height_value = (double)height;
    return base_area + PI * radius_value * sqrt(radius_squared + height_value * height_value);
}
