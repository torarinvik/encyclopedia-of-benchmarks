# Kronecker product

The pinned Python routine constructs the Kronecker product by iterating over entries of the first matrix, then entries of the second, placing each scaled block in row-major order. This bounded contract specializes the first input to a 2×2 matrix and the second to a 1×2 matrix.

## Contract

Input is six row-major integers `[a00,a01,a10,a11,b00,b01]`, each in [-10,10]. It represents A ⊗ B, an output matrix with two rows and four columns. The eight row-major output entries are packed as base-201 digits after adding 100 to each entry; malformed inputs return -1.

See [workload](workload.json), [oracle](../../kronecker_product_oracle.py), and pinned [Python source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/matrix/kronecker_product.py).

| Language | Port |
|---|---|
| C | c/k/kronecker_product.c |
| C3 | c3/k/kronecker_product.c3 |
| C++ | cpp/k/kronecker_product.cpp |
| Elisa | elisa/k/kronecker_product.elisa |
| Nim | nim/k/kronecker_product.nim |
| Odin | odin/k/kronecker_product.odin |
| Rust | rust/k/kronecker_product.rs |
| V | v/k/kronecker_product.v |
| Zig | zig/k/kronecker_product.zig |
