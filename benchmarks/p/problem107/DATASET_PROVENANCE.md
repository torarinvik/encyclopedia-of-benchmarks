# Problem 107 dataset provenance

Both local data files are copied from TheAlgorithms/Python revision `e1a2a8b016001309a73d5fec4818c35cca139795`.

| File | Upstream path | Shape | SHA-256 |
| --- | --- | --- | --- |
| [`p107_network.txt`](p107_network.txt) | `project_euler/problem_107/p107_network.txt` | 40×40 symmetric matrix, 513 undirected edges | `81f6b2c8da3b6f89cb6164b2bdf192a91d445095ef23b39bcfb75f0d4578c1c2` |
| [`test_network.txt`](test_network.txt) | `project_euler/problem_107/test_network.txt` | 7×7 symmetric matrix, 12 undirected edges | `44087788c5f12aa0b8767f873c65c269a66016fc379f3737edc1880669f558ad` |

Pinned upstream copies: [p107_network.txt](https://raw.githubusercontent.com/TheAlgorithms/Python/e1a2a8b016001309a73d5fec4818c35cca139795/project_euler/problem_107/p107_network.txt), [test_network.txt](https://raw.githubusercontent.com/TheAlgorithms/Python/e1a2a8b016001309a73d5fec4818c35cca139795/project_euler/problem_107/test_network.txt).

The workload encodes only the lower triangle without the diagonal, matching the pinned parser's edge extraction and avoiding duplicate values for undirected edges.
