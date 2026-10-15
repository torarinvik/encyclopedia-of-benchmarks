module bearing;

extern fn double sin(double value);
extern fn double cos(double value);
extern fn double atan2(double y, double x);

// Return a spherical initial bearing in integer microdegrees.
fn long bearing(long* values, usz length) @export("bearing") {
    if (values == null || length != 4) return -1;
    long latitude1_value = values[0];
    long longitude1_value = values[1];
    long latitude2_value = values[2];
    long longitude2_value = values[3];
    if (latitude1_value < -90000000 || latitude1_value > 90000000 ||
        latitude2_value < -90000000 || latitude2_value > 90000000 ||
        longitude1_value < -180000000 || longitude1_value > 180000000 ||
        longitude2_value < -180000000 || longitude2_value > 180000000 ||
        (latitude1_value == latitude2_value && longitude1_value == longitude2_value)) {
        return -1;
    }

    double radians_per_microdegree = 0.000001 * (3.14159265358979323846 / 180.0);
    double latitude1 = (double)latitude1_value * radians_per_microdegree;
    double longitude1 = (double)longitude1_value * radians_per_microdegree;
    double latitude2 = (double)latitude2_value * radians_per_microdegree;
    double longitude2 = (double)longitude2_value * radians_per_microdegree;
    double delta_longitude = longitude2 - longitude1;
    double east = sin(delta_longitude) * cos(latitude2);
    double north = cos(latitude1) * sin(latitude2) -
                   sin(latitude1) * cos(latitude2) * cos(delta_longitude);
    double degrees = atan2(east, north) * 57.2957795130823208768;
    if (degrees < 0.0) degrees += 360.0;
    long result = (long)(degrees * 1000000.0 + 0.5);
    return result >= 360000000 ? 0 : result;
}
