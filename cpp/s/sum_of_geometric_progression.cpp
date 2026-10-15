// Sum a finite geometric progression using the pinned closed form.
#include <cmath>

extern "C" double sum_of_geometric_progression(double first_term, double common_ratio,
                                                double num_terms)
{
    if (common_ratio == 1.0) return num_terms * first_term;
    return (first_term / (1.0 - common_ratio))
        * (1.0 - std::pow(common_ratio, num_terms));
}
