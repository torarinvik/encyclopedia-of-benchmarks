/// Convert ounces to kilograms with the pinned coefficient and operation order.
export fn ounces_to_kilograms(ounces: f64) f64 {
    if (ounces < -1000000.0 or ounces > 1000000.0) return -1e300;
    return (ounces * 28.3498) / 1000.0;
}
