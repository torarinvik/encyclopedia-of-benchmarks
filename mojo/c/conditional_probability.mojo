@export("conditional_probability")
fn conditional_probability(probability_intersection: Float64, probability_b: Float64) abi("C") -> Float64:
    if probability_intersection != probability_intersection or probability_b != probability_b or probability_b <= 0.0 or probability_b > 1.0 or probability_intersection < 0.0 or probability_intersection > probability_b: return -1.0
    return probability_intersection / probability_b
