module ounces_to_kilograms;

fn double ounces_to_kilograms(double ounces) @export("ounces_to_kilograms") {
    if (ounces < -1000000.0 || ounces > 1000000.0) return -1e300;
    return (ounces * 28.3498) / 1000.0;
}
