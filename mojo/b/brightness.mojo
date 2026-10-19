from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("brightness")
fn brightness(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length != 3: return -1
    for i in range(3):
        if input[i] < 0 or input[i] > 255: return -1
    let red = [2,37,139,14,2,20,252,71,168,119,186]
    let green = [99,44,169,255,28,33,227,65,80,35,13]
    let blue = [255,58,229,10,1,20,65,24,80,90,126]
    let labels = [1,0,1,1,0,0,1,0,1,0,1]
    var best_dist = 195076; var best = -1
    for i in range(11):
        let dr = input[0] - red[i]; let dg = input[1] - green[i]; let db = input[2] - blue[i]
        let dist = dr * dr + dg * dg + db * db
        if dist < best_dist: best_dist = dist; best = labels[i]
    return Int64(best)
