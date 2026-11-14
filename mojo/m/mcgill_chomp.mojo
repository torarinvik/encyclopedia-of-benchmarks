# Independently written bounded Chomp state-table profile.
from std.collections import List

fn chomp_enumerate(rows: Int, column: Int, minimum: Int, powers: List[Int],
                   mut heights: List[Int], mut outcomes: List[UInt8]):
    if column < 0:
        var index = 0
        for i in range(7): index += heights[i]*powers[i]
        var has_move = False
        var winning = False
        for row in range(rows):
            for selected in range(7):
                var child = 0
                var changed = False
                for i in range(7):
                    var height = heights[i]
                    if i >= selected and height > row:
                        height = row
                        changed = True
                    child += height*powers[i]
                if changed:
                    has_move = True
                    if outcomes[child] == 0: winning = True
        if has_move and not winning: outcomes[index] = 0
        else: outcomes[index] = 1
        return
    for height in range(minimum, rows+1):
        heights[column] = height
        chomp_enumerate(rows, column-1, height, powers, heights, outcomes)

@export("mcgill_chomp")
fn mcgill_chomp(rows_value: Int64) abi("C") -> Int64:
    if rows_value != 7 and rows_value != 8: return -1
    let rows = Int(rows_value)
    let base = rows+1
    var powers = List[Int](capacity=7)
    var power = 1
    for _ in range(7):
        powers.append(power)
        power *= base
    var heights = List[Int](capacity=7)
    for _ in range(7): heights.append(0)
    var outcomes = List[UInt8](capacity=power)
    for _ in range(power): outcomes.append(0)
    chomp_enumerate(rows, 6, 0, powers, heights, outcomes)
    var full = 0
    for i in range(7): full += rows*powers[i]
    return Int64(outcomes[full])
