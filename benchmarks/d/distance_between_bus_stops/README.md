# Distance Between Bus Stops

This benchmark implements the C LeetCode 1184 algorithm from TheAlgorithms/C. The input is packed as start index, destination index, then one distance for each stop. It sums the distances on the two routes around the circle and returns the smaller sum.

The contract accepts 1 to 64 stops, valid zero-based endpoint indices, and distances from 0 through 1,000,000. Invalid input returns -1. The bound keeps the maximum total in signed 32-bit range while implementations use signed 64-bit arithmetic.

The verifier compares all endpoint pairs and distance arrays of length at most four over values 0 through 3, plus deterministic boundary and random routes, against an exact Python summation oracle. The pinned source is [TheAlgorithms/C LeetCode 1184](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/leetcode/src/1184.c). Run the verifier with the Elisa stage1 compiler path supplied.
