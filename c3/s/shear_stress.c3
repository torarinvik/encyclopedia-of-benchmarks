module shear_stress;

fn double shear_stress(double stress, double tangential_force, double area) @export("shear_stress") {
    if (stress != stress || tangential_force != tangential_force || area != area ||
        stress < 0.0 || stress > 1000.0 || tangential_force < 0.0 || tangential_force > 1000.0 ||
        area < 0.0 || area > 1000.0 || stress != (double)(long)stress ||
        tangential_force != (double)(long)tangential_force || area != (double)(long)area) return -1.0;
    int zeros = 0;
    if (stress == 0.0) zeros++;
    if (tangential_force == 0.0) zeros++;
    if (area == 0.0) zeros++;
    if (zeros != 1) return -1.0;
    if (stress == 0.0) return tangential_force / area;
    if (tangential_force == 0.0) return stress * area;
    return tangential_force / stress;
}
