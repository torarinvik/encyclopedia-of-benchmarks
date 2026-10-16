module coulombs_law;

const double INVALID_RESULT = -1.0e300;
const double COULOMBS_CONSTANT = 8.9875517923e9;
const long MAX_CHARGE_MICROCOULOMBS = 1000000;
const long MAX_DISTANCE_MILLIMETERS = 1000000;

fn double coulombs_law(long* values, usz length) @export("coulombs_law") {
    if (values == null || length != 3) return INVALID_RESULT;
    long charge1_value = values[0], charge2_value = values[1], distance_value = values[2];
    if (charge1_value == 0 || charge2_value == 0 ||
        charge1_value < -MAX_CHARGE_MICROCOULOMBS || charge1_value > MAX_CHARGE_MICROCOULOMBS ||
        charge2_value < -MAX_CHARGE_MICROCOULOMBS || charge2_value > MAX_CHARGE_MICROCOULOMBS ||
        distance_value < 1 || distance_value > MAX_DISTANCE_MILLIMETERS) return INVALID_RESULT;

    double charge1 = (double)charge1_value / 1000000.0;
    double charge2 = (double)charge2_value / 1000000.0;
    double distance = (double)distance_value / 1000.0;
    double charge_product = charge1 * charge2;
    if (charge_product < 0.0) charge_product = -charge_product;
    return COULOMBS_CONSTANT * charge_product / (distance * distance);
}
