module dodecahedron;

extern fn double sqrt(double value);
const double INVALID_RESULT = -1.0e300;

fn double dodecahedron(long* values, usz length) @export("dodecahedron") {
    if (values == null || length != 2) return INVALID_RESULT;
    long edge = values[0];
    long quantity = values[1];
    if (edge < 1 || edge > 1000000 || (quantity != 0 && quantity != 1)) return INVALID_RESULT;

    double root_five = sqrt(5.0);
    if (quantity == 0) {
        double area_factor = 3.0 * sqrt(25.0 + 10.0 * root_five);
        return area_factor * (double)(edge * edge);
    }
    double volume_factor = (15.0 + 7.0 * root_five) / 4.0;
    return volume_factor * (double)(edge * edge * edge);
}
