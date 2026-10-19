@export("addition_rule")
fn addition_rule(probability_a: Float64, probability_b: Float64,
                 probability_b_given_a: Float64) abi("C") -> Float64:
    return (probability_a + probability_b) - (probability_a * probability_b_given_a)
