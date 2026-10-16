module liters_to_usgallons;

fn double liters_to_usgallons(double liters) @export("liters_to_usgallons") {
    if (liters != liters || liters < -1.0e100 || liters > 1.0e100) return -1.0e300;
    return liters / 3.785411784;
}
