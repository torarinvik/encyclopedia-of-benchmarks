# Chebyshev iteration

This benchmark ports the pinned Java `solve` routine for the Chebyshev iteration method. The input stores a square matrix, right-hand side, initial guess, spectral interval, iteration limit, and residual tolerance. Numeric inputs use signed integers scaled by 1,000,000; the solver converts them to binary64. The output is the best solution vector as little-endian binary64 values.

The solver initializes `r = b - A*x0`, uses the source's `alpha`/`beta` recurrence, recomputes the residual after each update, stops only when its Euclidean norm is strictly less than the tolerance, and returns the current iterate if the iteration limit is reached. The source assumes an SPD matrix and valid eigenvalue bounds but does not verify either property; workload and generated valid cases satisfy those assumptions. Structural or bounded-domain violations return `-1`. A valid input with less than `8*n` output bytes returns `-2`; success returns `8*n`.

Input layout is `[n, A row-major (n*n), b (n), x0 (n), min_eigenvalue, max_eigenvalue, max_iterations, tolerance]`. The dimension is 1 through 8. Matrix and vector values are bounded to ±1000 before scaling; spectral bounds must be positive, increasing, and no greater than 1000. Iteration limits are 1 through 1000 and tolerance is positive.

The independent oracle and workload include exact initial solutions, diagonal and dense SPD systems, early stopping, iteration-limit results, maximum dimension, malformed inputs, and short output capacity. The pinned implementation is [TheAlgorithms/Java `ChebyshevIteration.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/maths/ChebyshevIteration.java).
