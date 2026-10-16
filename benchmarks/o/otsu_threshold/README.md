# Otsu threshold

This benchmark follows the pinned Python `otsu_threshold` implementation for a grayscale image. The input is a flattened row-major byte image `[pixel_count, pixel_0, ...]`; the bounded contract accepts 1–32 pixels with intensities 0–255. It builds the 256-bin histogram, walks thresholds from 0 through 255, and retains the first threshold with a strictly greater between-class variance. Pixels strictly greater than the selected threshold become 255; all others become 0. The result is the raw output pixel byte sequence.

The finite workload avoids image-library and file-I/O costs while preserving the source histogram, threshold, tie, and pixel-comparison semantics. The runtime oracle is `otsu_threshold_oracle.py`.
