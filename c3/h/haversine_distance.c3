module haversine_distance;

const double INVALID_RESULT = -1.0e300;
const double PI_VALUE = 3.14159265358979323846264338327950288;
extern fn double sin(double value);
extern fn double cos(double value);
extern fn double sqrt(double value);
extern fn double asin(double value);
extern fn double atan2(double y, double x);

fn bool valid_coordinates(long* values, usz length) {
    if (values == null || length != 4) return false;
    if (values[0] < -90000000 || values[0] > 90000000) return false;
    if (values[2] < -90000000 || values[2] > 90000000) return false;
    if (values[1] < -180000000 || values[1] > 180000000) return false;
    if (values[3] < -180000000 || values[3] > 180000000) return false;
    return true;
}

fn double haversine_a(long* values) {
    double radians_per_microdegree = PI_VALUE / 180000000.0;
    double latitude1 = (double)values[0] * radians_per_microdegree;
    double longitude1 = (double)values[1] * radians_per_microdegree;
    double latitude2 = (double)values[2] * radians_per_microdegree;
    double longitude2 = (double)values[3] * radians_per_microdegree;
    double delta_latitude = latitude2 - latitude1;
    double delta_longitude = longitude2 - longitude1;
    double sin_latitude = sin(delta_latitude / 2.0);
    double sin_longitude = sin(delta_longitude / 2.0);
    double a = sin_latitude * sin_latitude +
        cos(latitude1) * cos(latitude2) * sin_longitude * sin_longitude;
    if (a < 0.0) a = 0.0;
    if (a > 1.0) a = 1.0;
    return a;
}

fn double haversine_distance(long* values, usz length) @export("haversine_distance") {
    if (!valid_coordinates(values, length)) return INVALID_RESULT;
    double a = haversine_a(values);
    return 2.0 * atan2(sqrt(a), sqrt(1.0 - a)) * 6371.0;
}
