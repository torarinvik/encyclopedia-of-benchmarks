@export("remove_digit")
fn remove_digit(value: Int64) abi("C") -> Int64:
    if value == -9223372036854775808 or value > 9223372036854775807 or value < -9223372036854775807: return -1
    let magnitude = if value < 0: -value else: value
    if magnitude < 10: return -1
    var place: Int64 = 1
    while place <= magnitude / 10: place *= 10
    var maximum: Int64 = 0
    var removed_place = place
    while removed_place > 0:
        let high = (magnitude / removed_place) / 10
        let low = magnitude % removed_place
        let candidate = high * removed_place + low
        if candidate > maximum: maximum = candidate
        removed_place /= 10
    return maximum
