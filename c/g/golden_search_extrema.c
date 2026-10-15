#include <math.h>

#define EPSILON 1.0e-7
#define MIN_WIDTH 2.0e-7
#define INVALID_RESULT (-1.0)
#define MAX_ITERATIONS 128

static double objective(int id, double x) { return id == 0 ? (x - 2.0) * (x - 2.0) : cos(x); }

double golden_search_extrema(double objective_id, double left, double right) {
    if (objective_id != 0.0 && objective_id != 1.0) return INVALID_RESULT;
    if (objective_id == 0.0 && (!(left >= 0.0 && left <= 4.0) || !(right >= 0.0 && right <= 4.0))) return INVALID_RESULT;
    if (objective_id == 1.0 && (!(left >= 2.0 && left <= 4.0) || !(right >= 2.0 && right <= 4.0))) return INVALID_RESULT;
    double a = left, b = right;
    if (a > b) { double t = a; a = b; b = t; }
    if (b - a < MIN_WIDTH) return INVALID_RESULT;
    if (objective_id == 0.0 ? !(a < 2.0 && 2.0 < b) : !(a < 3.14159265358979323846 && 3.14159265358979323846 < b)) return INVALID_RESULT;

    double mean = INFINITY, previous_mean = INFINITY;
    const double phi = 1.61803400516510009765625;
    for (int iteration = 0; iteration < MAX_ITERATIONS && fabs(b - a) > EPSILON; ++iteration) {
        previous_mean = mean;
        double ratio = (b - a) / phi;
        double c = b - ratio;
        double d = a + ratio;
        if (objective((int)objective_id, c) < objective((int)objective_id, d)) b = d;
        else a = c;
        mean = (a + b) / 2.0;
    }
    return previous_mean;
}
