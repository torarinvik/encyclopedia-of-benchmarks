module radian_to_degree;

const double INVALID_RESULT = -1.0e300;

fn double radian_to_degree(double radian) @export("radian_to_degree") {
    if (!(radian >= -1000000.0 && radian <= 1000000.0)) return INVALID_RESULT;
    return radian * (180.0 / 3.141592653589793);
}
