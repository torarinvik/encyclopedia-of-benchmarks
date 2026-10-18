# Sepia BGR pixel transform

This benchmark covers the numeric core of the pinned Python `make_sepia` function. Image loading, display, and the command-line demo are outside the operation.

## Contract

Input is `[height, width, factor, B0, G0, R0, ...]`. Height and width are each 1 through 8; `factor` is an integer from 0 through 255. There are `height * width` pixels in row-major order, with three BGR channel values per pixel. Every channel must be in `{0, 64, 128, 255}`. The packed signed-i64 input has exact length `3 + 3*height*width`; the maximum valid length is 195 words and the maximum parseable length is 196 for an extra-word framing probe.

For each BGR input pixel, unpack `blue`, `green`, and `red`, then calculate the grayscale value in the source operation order:

```text
gray = int(0.2126*red + 0.587*green + 0.114*blue)
```

The allowed channel levels keep every nonblack grayscale value at least 0.019 away from an integer boundary (black is exactly zero), so truncation remains stable across implementations. The output pixel preserves BGR channel order and is `[gray, min(gray+factor,255), min(gray+2*factor,255)]`. The transform returns raw BGR bytes for the same row-major shape; no lower clamp is needed because the factor and input channels are nonnegative.

Output has exactly `3*height*width` bytes, at most 192. A valid call returns the byte length. Malformed framing, unsupported dimensions or factor, or a channel outside the declared set returns `-1` before output checks. A null output pointer or insufficient capacity returns `-2` after input validation. Errors write no output bytes.

The independent oracle is [`../../sepia_oracle.py`](../../sepia_oracle.py). The workload includes black and primary-color pixels, mixed channel levels, factor endpoints, saturation, maximum shape, malformed frames, and output-capacity edges.

## Pinned source

- Python [`sepia.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/digital_image_processing/sepia.py), specifically `make_sepia(img, factor)`. The function mutates and returns its input image; this adapter returns the resulting pixel bytes.

## Language ports

| Language | Port |
|---|---|
| C | [`c/s/sepia.c`](../../../c/s/sepia.c) |
| C3 | [`c3/s/sepia.c3`](../../../c3/s/sepia.c3) |
| C++ | [`cpp/s/sepia.cpp`](../../../cpp/s/sepia.cpp) |
| Elisa | [`elisa/s/sepia.elisa`](../../../elisa/s/sepia.elisa) |
| Nim | [`nim/s/sepia.nim`](../../../nim/s/sepia.nim) |
| Odin | [`odin/s/sepia.odin`](../../../odin/s/sepia.odin) |
| Rust | [`rust/s/sepia.rs`](../../../rust/s/sepia.rs) |
| V | [`v/s/sepia.v`](../../../v/s/sepia.v) |
| Zig | [`zig/s/sepia.zig`](../../../zig/s/sepia.zig) |
