module liters_to_imperial_gallons;

fn double liters_to_imperial_gallons(double liters) @export("liters_to_imperial_gallons") {
    if (liters != liters || liters < -1.0e100 || liters > 1.0e100) return -1.0e300;
    return liters / 4.54609;
}
