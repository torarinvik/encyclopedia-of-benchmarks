# Blob detection

Segment RGB8 pixels by the source's HSV thresholds, open the binary mask with a radius-3 disk, and count 8-connected blobs whose areas are between 200 and 5000 pixels.

## Contract

- Input is `[height, width, profile, r0, g0, b0, r1, g1, b1, ...]`, with row-major RGB channels in the range 0–255. Height and width are 1–128. Profile 0 uses the thresholds from `blobDetection.m`; profile 1 uses those from `BlobUsingVideo.m`.
- Profile 0 accepts hue 0.379–0.496 and saturation at least 0.436. Profile 1 accepts hue 0.398–0.498 and saturation at least 0.355. All bounds are inclusive, value has the full source range 0–1, and RGB-to-HSV comparisons use equivalent rational integer comparisons so all ports agree at boundaries.
- Morphological opening is erosion then dilation using every integer offset `(dy, dx)` with `dx² + dy² <= 9`. Binary erosion treats pixels outside the image as foreground; dilation treats them as background, matching MATLAB morphology border rules. Connected components use 8-neighbor connectivity. Areas 200 and 5000 are included. At most 50 accepted blobs are counted, matching `vision.BlobAnalysis`'s default maximum count.
- The function returns the accepted blob count; malformed input returns `-1`.

## Source normalization

The pinned MATLAB files are demos: `blobDetection.m` loads an unprovided `sampleFrames.mat`, while `BlobUsingVideo.m` reads an unprovided AVI file. Both depend on MATLAB image and vision toolboxes. This benchmark isolates their shared RGB thresholding, morphology, and blob-counting path; the profile field preserves each demo's HSV thresholds. Both call `strel('disk',3)` with MATLAB's default four-line disk approximation; this portable contract uses the exact radius-3 pixel disk (`n=0`) to make the structuring element explicit across languages. The demos display or use only the count here, so this benchmark returns that count rather than annotated images or unused centroid and bounding-box arrays.

## Workload and verification

[`workload.json`](workload.json) covers both HSV profiles, inclusive area bounds, morphology, border behavior, diagonal regions, the 50-object limit, and malformed inputs. Verify with `python3 benchmarks/verify_blob_detection.py --elisa-compiler ../Elisa-compiler/bin/elisac-stage1`.

## Pinned source

- TheAlgorithms/MATLAB-Octave [`blobDetection.m`](https://github.com/TheAlgorithms/MATLAB-Octave/blob/e150b77ad256de46c1ce3815c3d7945ac4fc28dc/image-processing/Blob-detection-using-Matlab/blobDetection.m)
- TheAlgorithms/MATLAB-Octave [`BlobUsingVideo.m`](https://github.com/TheAlgorithms/MATLAB-Octave/blob/e150b77ad256de46c1ce3815c3d7945ac4fc28dc/image-processing/Blob-detection-using-Matlab/BlobUsingVideo.m)

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/b/blob_detection.c`](../../../c/b/blob_detection.c) |
| C3 | [`c3/b/blob_detection.c3`](../../../c3/b/blob_detection.c3) |
| C++ | [`cpp/b/blob_detection.cpp`](../../../cpp/b/blob_detection.cpp) |
| Elisa | [`elisa/b/blob_detection.elisa`](../../../elisa/b/blob_detection.elisa) |
| Nim | [`nim/b/blob_detection.nim`](../../../nim/b/blob_detection.nim) |
| Odin | [`odin/b/blob_detection.odin`](../../../odin/b/blob_detection.odin) |
| Rust | [`rust/b/blob_detection.rs`](../../../rust/b/blob_detection.rs) |
| V | [`v/b/blob_detection.v`](../../../v/b/blob_detection.v) |
| Zig | [`zig/b/blob_detection.zig`](../../../zig/b/blob_detection.zig) |
