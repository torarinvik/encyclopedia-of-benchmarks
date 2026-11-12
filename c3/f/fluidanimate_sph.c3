module fluidanimate_sph;

const usz MAX_PARTICLES = 32;
const usz MAX_INPUT_LENGTH = 2 + 6 * MAX_PARTICLES;
const double PI = 3.14159265358979323846264338327950288;
extern fn double pow(double base, double exponent);
extern fn double sqrt(double value);

fn void store_f64_le(char *output, usz offset, double value) {
    ulong bits = @bitcast(ulong, value);
    for (usz byte = 0; byte < 8; byte++) {
        output[offset + byte] = (char)(bits & 255);
        bits >>= 8;
    }
}

fn long fluidanimate_sph(long *input, usz length, char *output, usz capacity)
    @export("fluidanimate_sph") {
    if (input == null || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    long count_value = input[0], rpm_milli = input[1];
    if (count_value < 1 || count_value > 32 || rpm_milli < 500 || rpm_milli > 5000) return -1;
    usz count = (usz)count_value;
    if (length != 2 + 6 * count) return -1;
    for (usz i = 0; i < count; i++) {
        usz base = 2 + 6 * i;
        for (usz axis = 0; axis < 3; axis++)
            if (input[base + axis] < -10000 || input[base + axis] > 10000) return -1;
        for (usz axis = 3; axis < 6; axis++)
            if (input[base + axis] < -5000 || input[base + axis] > 5000) return -1;
    }
    usz output_bytes = 40 * count;
    if (output == null || capacity < output_bytes) return -2;

    double[MAX_PARTICLES][3] position = zeroed;
    double[MAX_PARTICLES][3] velocity = zeroed;
    double[MAX_PARTICLES][3] acceleration = zeroed;
    double[MAX_PARTICLES] density = zeroed;
    double rpm = (double)rpm_milli / 1000.0;
    double h = 1.695 / rpm, h2 = h * h;
    double mass = 1000.0 / (rpm * rpm * rpm);
    double density_coeff = mass * (315.0 / (64.0 * PI * pow(h, 9.0)));
    double pressure_coeff = 3.0 * (15.0 / (PI * pow(h, 6.0))) * 1.5 * mass;
    double viscosity_coeff = 0.4 * (45.0 / (PI * pow(h, 6.0))) * mass;
    for (usz i = 0; i < count; i++) {
        usz base = 2 + 6 * i;
        for (usz axis = 0; axis < 3; axis++) {
            position[i][axis] = (double)input[base + axis] / 1000.0;
            velocity[i][axis] = (double)input[base + 3 + axis] / 1000.0;
            acceleration[i][axis] = axis == 1 ? -9.8 : 0.0;
        }
        density[i] = density_coeff * h2 * h2 * h2;
    }
    for (usz i = 0; i < count; i++) {
        for (usz j = i + 1; j < count; j++) {
            double dx = position[i][0] - position[j][0];
            double dy = position[i][1] - position[j][1];
            double dz = position[i][2] - position[j][2];
            double r2 = dx * dx + dy * dy + dz * dz;
            if (r2 < h2) {
                double term = density_coeff * pow(h2 - r2, 3.0);
                density[i] += term;
                density[j] += term;
            }
        }
    }
    for (usz i = 0; i < count; i++) {
        for (usz j = i + 1; j < count; j++) {
            double dx = position[i][0] - position[j][0];
            double dy = position[i][1] - position[j][1];
            double dz = position[i][2] - position[j][2];
            double r2 = dx * dx + dy * dy + dz * dz;
            if (r2 >= h2) continue;
            double guarded_r2 = r2 > 1e-12 ? r2 : 1e-12;
            double distance = sqrt(guarded_r2);
            double hmr = h - distance;
            double rho_product = density[i] * density[j];
            double pressure_scale = pressure_coeff * (hmr * hmr / distance)
                * (density[i] + density[j] - 2000.0) / rho_product;
            double viscosity_scale = viscosity_coeff * hmr / rho_product;
            double disp[3] = {dx, dy, dz};
            for (usz axis = 0; axis < 3; axis++) {
                double force = disp[axis] * pressure_scale
                    + (velocity[j][axis] - velocity[i][axis]) * viscosity_scale;
                acceleration[i][axis] += force;
                acceleration[j][axis] -= force;
            }
        }
    }
    for (usz i = 0; i < count; i++) {
        double fields[5] = {density[i], 3.0 * (density[i] - 1000.0),
            acceleration[i][0], acceleration[i][1], acceleration[i][2]};
        for (usz field = 0; field < 5; field++) store_f64_le(output, 8 * (5 * i + field), fields[field]);
    }
    return (long)output_bytes;
}
