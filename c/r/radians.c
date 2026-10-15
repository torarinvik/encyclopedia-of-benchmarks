/* Convert degrees to radians using the pinned expression order. */
#define INVALID_RESULT (-1.0e300)

double radians(double degree)
{
    if (!(degree >= -1000000.0 && degree <= 1000000.0)) return INVALID_RESULT;
    return degree / (180.0 / 3.141592653589793);
}
