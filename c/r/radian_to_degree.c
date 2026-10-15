/* Convert radians to degrees using the pinned expression order. */
#define INVALID_RESULT (-1.0e300)

double radian_to_degree(double radian)
{
    if (!(radian >= -1000000.0 && radian <= 1000000.0)) return INVALID_RESULT;
    return radian * (180.0 / 3.141592653589793);
}
