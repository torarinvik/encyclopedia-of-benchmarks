# One-dimensional cellular automaton

This benchmark preserves the pinned Python source's fixed 31-cell row, live center seed, 8-bit elementary cellular automaton rule, and 16-generation run. The source passes the binary digits of the conventional rule number as a decimal integer to its rule formatter. Accordingly the single input is that digit string parsed as a decimal integer (rule 30 is `11110`), padded on the left to eight bits; valid values contain only decimal digits 0 and 1 and range from 0 through 11111111.

Output contains the seed and all 16 generated rows as row-major RGB bytes. A live cell is black `(0,0,0)` and a dead cell is white `(255,255,255)`, matching the source image color mapping. The result is always 1581 bytes. Invalid input returns `-1`; insufficient output capacity returns `-2`. `one_dimensional_oracle.py` supplies the runtime expected output.
