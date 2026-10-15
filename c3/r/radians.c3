module radians;

const double INVALID_RESULT = -1.0e300;

fn double radians(double degree) @export("radians") {
    if (!(degree >= -1000000.0 && degree <= 1000000.0)) return INVALID_RESULT;
    return degree / (180.0 / 3.141592653589793);
}
