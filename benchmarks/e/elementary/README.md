# Elementary cellular automaton (Rule 30)

The benchmark computes one generation of Wolfram Rule 30 over a finite one-dimensional row. Input is `[cell_count, cell_0, ...]`, with 1–128 binary cells and the first cell fixed to zero. The fixed first cell keeps the pinned JavaScript source's left-neighbor indexing behavior equivalent to the pinned Python Rule 30 function. Both use dead cells beyond the row edges. Output is one byte per resulting cell, each byte 0 or 1.

The benchmark follows the pinned JavaScript `getNextElementaryGeneration` restricted to rule 30 and the pinned Python `rule_30_step`. The JavaScript `elementary_cellular_automaton` candidate is a source-compatible alias under this restricted contract. See the [JavaScript source](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Cellular-Automata/Elementary.js) and [Python source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/cellular_automata/elementary_cellular_automaton.py).

The Python source also exposes `generate_rule_30(size, generations)`, which creates a centered seed and returns multiple generations. That wrapper is covered separately by [`generate_rule_30_grid`](../g/generate_rule_30_grid/README.md).
