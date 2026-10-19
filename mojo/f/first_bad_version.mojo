@export("first_bad_version")
fn first_bad_version(version_count: UInt64, first_bad: UInt64) abi("C") -> Int64:
    if version_count == 0 or version_count > 2147483647 or first_bad == 0 or first_bad > version_count: return -1
    var low: UInt64 = 1
    var high = version_count
    while low < high:
        let middle = low + (high - low) / 2
        if middle >= first_bad: high = middle
        else: low = middle + 1
    return Int64(low)
