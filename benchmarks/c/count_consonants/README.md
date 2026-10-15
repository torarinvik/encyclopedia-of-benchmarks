# Count consonants

Counts ASCII consonant letters in a string using the pinned PHP routine's character scan.

## Contract

- Uses i64_array_scalar; each array element is one printable ASCII code value in 32..126.
- The array length is 1..4096, except the exact one-character string 0 ([48]), which is invalid.
- Fold ASCII uppercase letters to lowercase, then count only a..z letters that are not a, e, i, o, or u.
- Ignore digits, spaces, punctuation, and other nonletters.
- Empty input and the exact string 0 return -1, matching the source's exception cases. Other malformed inputs also return -1.

## Source semantics

This follows pinned [TheAlgorithms PHP CountConsonants.php](https://github.com/TheAlgorithms/PHP/blob/b8a54469cc36332ef2934101b58d71075ef1d78e/Strings/CountConsonants.php). It rejects empty input and the exact string 0, converts the string to lowercase, and counts a character only when it lies between a and z and is not in the vowel set. The benchmark uses printable ASCII so case conversion has the same behavior in all nine ports. This counts consonants only among letters; punctuation and digits are ignored, so it is not computed as string length minus vowel count.

This is distinct from [count_vowels](../count_vowels/README.md), which counts vowels. The two scans share a string encoding but classify different letters.

## Workload and build

The workload covers all-vowel and consonant strings, mixed case, digits, punctuation, spaces, the empty string, the exact 0 special case, and malformed values. Build and record with the existing array scalar ABI:

    python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm count_consonants --language rust
    python3 benchmarks/run_i64_array_scalar.py --build-manifest build/i64_array_scalar/c/count_consonants/rust/build.json

The nine implementations are in c/c/count_consonants.c, c3/c/count_consonants.c3, cpp/c/count_consonants.cpp, elisa/c/count_consonants.elisa, nim/c/count_consonants.nim, odin/c/count_consonants.odin, rust/c/count_consonants.rs, v/c/count_consonants.v, and zig/c/count_consonants.zig.
