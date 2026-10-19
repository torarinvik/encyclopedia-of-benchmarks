@export("bayes_theorem")
fn bayes_theorem(probability_a: Float64, probability_b: Float64,
                probability_b_given_a: Float64) abi("C") -> Float64:
    if not (probability_a >= 0.0 and probability_a <= 1.0 and
            probability_b > 0.0 and probability_b <= 1.0 and
            probability_b_given_a >= 0.0 and probability_b_given_a <= 1.0 and
            probability_a * probability_b_given_a <= probability_b):
        return -1.0
    return probability_b_given_a * probability_a / probability_b
