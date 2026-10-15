module sum_of_geometric_progression;

extern fn double pow(double base, double exponent);

fn double sum_of_geometric_progression(double first_term, double common_ratio,
                                      double num_terms) @export("sum_of_geometric_progression") {
    if (common_ratio == 1.0) return num_terms * first_term;
    return (first_term / (1.0 - common_ratio))
        * (1.0 - pow(common_ratio, num_terms));
}
