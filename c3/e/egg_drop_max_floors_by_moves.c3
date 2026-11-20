module egg_drop_max_floors_by_moves;

const usz MAX_EGGS = 32;
const usz MAX_MOVES = 32;

fn long egg_drop_max_floors_by_moves(long* input, usz length) @export("egg_drop_max_floors_by_moves") {
    if (input == null || length != 2) return -1;
    long eggs = input[0], moves = input[1];
    if (eggs < 0 || eggs > (long)MAX_EGGS || moves < 0 || moves > (long)MAX_MOVES) return -1;
    long[33] covered;
    for (usz egg = 0; egg <= MAX_EGGS; egg++) covered[egg] = 0;
    for (long move = 0; move < moves; move++) {
        for (long egg = eggs; egg > 0; egg--) covered[egg] += covered[egg - 1] + 1;
    }
    return covered[eggs];
}
