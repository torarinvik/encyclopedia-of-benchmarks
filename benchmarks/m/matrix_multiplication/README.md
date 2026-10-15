# Matrix multiplication

Multiply two square matrices using the classical row-by-column algorithm. The shared input domain is restricted to square matrices so the Java, TypeScript, and JavaScript source implementations have the same result behavior. This excludes JavaScript's one-row checker failure and the rectangular cases supported by the Java and TypeScript implementations.

Pinned source implementations:

- Java: [TheAlgorithms/Java `MatrixMultiplication.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/matrix/MatrixMultiplication.java)
- JavaScript: [TheAlgorithms/JavaScript `MatrixMultiplication.js`](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Maths/MatrixMultiplication.js)
- TypeScript: [TheAlgorithms/TypeScript `matrix_multiplication.ts`](https://github.com/TheAlgorithms/TypeScript/blob/19b4ced86c99815f142d4a46a028f55487b8038a/maths/matrix_multiplication.ts)

## Contract

Input is packed signed 64-bit slots `[n, A row-major values..., B row-major values...]`. The dimension `n` is 2 through 8, and each matrix has exactly `n*n` cells. Each cell is an integer from -1000 through 1000. These bounds keep each product and accumulated result exact in binary64 while also allowing exact signed 64-bit output.

The output is the row-major product matrix encoded as little-endian signed 64-bit cells. The function returns `n*n`; malformed input or an out-of-domain value returns `-2`, and a null or undersized output buffer returns `-3`.

The reference algorithms use row, column, inner-index loop order. The ports preserve that order and use the same multiply-then-accumulate operation.
