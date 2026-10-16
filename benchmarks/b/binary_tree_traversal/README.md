# Binary tree traversal

Traverse a bounded rooted binary tree in preorder, inorder, postorder, reverse-inorder, breadth-first, or zigzag order. Breadth-first mode 3 visits each level left-to-right; mode 4 visits each level right-to-left; mode 6 alternates direction by level. This covers the traversal functions exposed by the pinned sources.

Pinned sources:

- Dart: [TheAlgorithms/Dart `binary_tree_traversal.dart`](https://github.com/TheAlgorithms/Dart/blob/73da8ab4ea413eee9bf29aa2263157d86060f871/data_structures/binary_tree/binary_tree_traversal.dart)
- PHP: [TheAlgorithms/PHP `BinaryTreeTraversal.php`](https://github.com/TheAlgorithms/PHP/blob/b8a54469cc36332ef2934101b58d71075ef1d78e/DataStructures/BinarySearchTree/BinaryTreeTraversal.php)
- PHP: [TheAlgorithms/PHP AVL `TreeTraversal.php`](https://github.com/TheAlgorithms/PHP/blob/b8a54469cc36332ef2934101b58d71075ef1d78e/DataStructures/AVLTree/TreeTraversal.php)
- Python: [TheAlgorithms/Python `binary_tree_traversal.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/searches/binary_tree_traversal.py)
- Python: [TheAlgorithms/Python `binary_tree_traversals.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/data_structures/binary_tree/binary_tree_traversals.py)
- Haskell: [TheAlgorithms/Haskell `BinaryTree.hs`](https://github.com/TheAlgorithms/Haskell/blob/9dcabef99fb8995a760ff25a9e0d659114c0b9d3/src/BinaryTree/BinaryTree.hs)
- Java: [TheAlgorithms/Java `BinaryTree.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/datastructures/trees/BinaryTree.java)
- Java: [TheAlgorithms/Java `InorderTraversal.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/datastructures/trees/InorderTraversal.java)
- Java: [TheAlgorithms/Java `PreOrderTraversal.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/datastructures/trees/PreOrderTraversal.java)
- Java: [TheAlgorithms/Java `ZigzagTraversal.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/datastructures/trees/ZigzagTraversal.java)
- C: [TheAlgorithms/C `recursive_traversals.c`](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/data_structures/binary_trees/recursive_traversals.c)
- C++: [TheAlgorithms/C-Plus-Plus `recursive_tree_traversal.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/others/recursive_tree_traversal.cpp)
- C++: [TheAlgorithms/C-Plus-Plus-1 `recursive_tree_traversal.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/others/recursive_tree_traversal.cpp)
- Python: [TheAlgorithms/Python `inorder_tree_traversal_2022.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/data_structures/binary_tree/inorder_tree_traversal_2022.py)
- Ruby: [TheAlgorithms/Ruby `preorder_traversal.rb`](https://github.com/TheAlgorithms/Ruby/blob/bda11bdfd83b7958e1ca98247e5e43100ca88865/data_structures/binary_trees/preorder_traversal.rb)
- Ruby: [TheAlgorithms/Ruby `inorder_traversal.rb`](https://github.com/TheAlgorithms/Ruby/blob/bda11bdfd83b7958e1ca98247e5e43100ca88865/data_structures/binary_trees/inorder_traversal.rb)
- C#: [TheAlgorithms/C-Sharp `BreadthFirstTreeTraversal.cs`](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms/Graph/BreadthFirstTreeTraversal.cs), whose left-to-right level-order method maps to mode 3.
- JavaScript: [TheAlgorithms/JavaScript `BreadthFirstTreeTraversal.js`](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Trees/BreadthFirstTreeTraversal.js), whose left-to-right level-order method maps to mode 3.
- Haskell: [TheAlgorithms/Haskell `BinaryTree.hs`](https://github.com/TheAlgorithms/Haskell/blob/9dcabef99fb8995a760ff25a9e0d659114c0b9d3/src/BinaryTree/BinaryTree.hs)
- Java: [TheAlgorithms/Java `BinaryTree.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/datastructures/trees/BinaryTree.java)

## Contract

Input is a signed 64-bit array `[order, node_count, root_index, (value, left_child, right_child)*]`. Order 0 selects preorder, 1 inorder, 2 postorder, 3 breadth-first left-to-right, 4 breadth-first right-to-left, 5 reverse-inorder, and 6 zigzag breadth-first (left-to-right on even-numbered levels and right-to-left on odd-numbered levels). The tree has 0 through 64 nodes. Child and root references are node indices, with `-1` representing no child; an empty tree has root `-1`.

For a nonempty tree, the root must have no parent, each other node must have one parent, and every node must be reachable from the root. Self-links, shared children, out-of-range references, cycles, and disconnected components are rejected with `-1`. The pinned recursive routines do not define behavior for malformed cyclic or shared-node structures, so the ABI rejects those structures before traversal. Payloads may repeat; the PHP port uses distinct synthetic node keys and preserves each node in its iterator.

Output is the selected traversal's payload sequence as little-endian signed 64-bit values. The function returns the output byte count, `-1` for invalid input, and `-2` for a null or undersized output buffer. An empty tree returns zero bytes.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/b/binary_tree_traversal.c`](../../../c/b/binary_tree_traversal.c) |
| C3 | [`c3/b/binary_tree_traversal.c3`](../../../c3/b/binary_tree_traversal.c3) |
| C++ | [`cpp/b/binary_tree_traversal.cpp`](../../../cpp/b/binary_tree_traversal.cpp) |
| Elisa | [`elisa/b/binary_tree_traversal.elisa`](../../../elisa/b/binary_tree_traversal.elisa) |
| Nim | [`nim/b/binary_tree_traversal.nim`](../../../nim/b/binary_tree_traversal.nim) |
| Odin | [`odin/b/binary_tree_traversal.odin`](../../../odin/b/binary_tree_traversal.odin) |
| Rust | [`rust/b/binary_tree_traversal.rs`](../../../rust/b/binary_tree_traversal.rs) |
| V | [`v/b/binary_tree_traversal.v`](../../../v/b/binary_tree_traversal.v) |
| Zig | [`zig/b/binary_tree_traversal.zig`](../../../zig/b/binary_tree_traversal.zig) |
