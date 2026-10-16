module geo_location;

const double PI = 3.14159265358979323846264338327950288;
extern fn double sin(double value);
extern fn double cos(double value);
extern fn double sqrt(double value);
extern fn double atan2(double y, double x);

fn long geo_location(double* values, usz length, double* output, usz capacity) @export("geo_location") {
    if (values == null || length != 4) return -1;
    for (usz i = 0; i < 4; i++) if (values[i] != values[i] || values[i] > 1.0e100 || values[i] < -1.0e100) return -1;
    double lat1d = values[0], lon1d = values[1], lat2d = values[2], lon2d = values[3];
    if (lat1d < -90.0 || lat1d > 90.0 || lat2d < -90.0 || lat2d > 90.0 ||
        lon1d < -180.0 || lon1d > 180.0 || lon2d < -180.0 || lon2d > 180.0) return -1;
    double factor = PI / 180.0;
    double lat1 = lat1d * factor, lon1 = lon1d * factor;
    double lat2 = lat2d * factor, lon2 = lon2d * factor;
    double diff_lat = lat2 - lat1, diff_lon = lon2 - lon1;
    double sin_lat = sin(diff_lat / 2.0), sin_lon = sin(diff_lon / 2.0);
    double haversine = sin_lat * sin_lat + cos(lat1) * cos(lat2) * sin_lon * sin_lon;
    if (haversine < 0.0 || haversine > 1.0) return -1;
    if (output == null || capacity < 1) return -2;
    output[0] = 6371010.0 * (2.0 * atan2(sqrt(haversine), sqrt(1.0 - haversine)));
    return 1;
}
