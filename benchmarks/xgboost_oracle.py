"""Independent oracle for the bounded Embench xgboost inference profile."""
from collections.abc import Sequence

FEATURES = 64
# Six fixed source-shaped trees, grouped as two vote trees per class.
FEATURE = (0,1,2, 3,4,5, 6,7,8, 9,10,11, 12,13,14, 15,16,17)
THRESHOLD = (100,100,100, 128,120,110, 90,140,80, 110,100,200, 150,150,150, 70,130,180)
LEFT = (1,128,130) * 6
RIGHT = (2,129,131) * 6
LEAVES = (1,0,0,2, 0,2,1,0, 0,1,2,0, 1,0,0,2, 2,0,1,0, 0,2,1,0)


def oracle(values: Sequence[int]) -> int:
    if len(values) != FEATURES or any(type(x) is not int or not 0 <= x <= 255 for x in values):
        return -1
    scores = [0, 0, 0]
    for tree in range(6):
        base = tree * 3
        node = 0
        while node < 128:
            at = base + node
            node = LEFT[at] if values[FEATURE[at]] < THRESHOLD[at] else RIGHT[at]
        scores[tree // 2] += LEAVES[tree * 4 + (node & 127)]
    return max(range(3), key=lambda c: (scores[c], -c))
