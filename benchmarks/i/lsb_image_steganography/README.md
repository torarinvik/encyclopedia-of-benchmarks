# LSB image steganography

This package ports the pinned MATLAB-Octave image steganography kernel to a bounded grayscale byte array. It embeds an ASCII message in the least significant bits of pixels in row-major order. The source reads image files, converts RGB images to grayscale, prompts for a message, and displays/writes images; the benchmark isolates the deterministic embedding kernel.

Source: [TheAlgorithms/MATLAB-Octave `steganography.m`](https://github.com/TheAlgorithms/MATLAB-Octave/blob/e150b77ad256de46c1ce3815c3d7945ac4fc28dc/algorithms/ImageProcessing/LSB%20based%20Image%20Steganography/steganography.m), commit `e150b77ad256de46c1ce3815c3d7945ac4fc28dc`.

## Contract

The `i64_array_bytes_output` input is `[rows, columns, message_length, pixel_values..., ASCII_bytes...]`. Rows and columns are 1 through 16; message length is 0 through 32 bytes and must fit in the pixel array (`8 * message_length <= rows * columns`). Pixel values are 0 through 254 and message bytes are ASCII 0 through 127. The input length must be exactly `3 + rows * columns + message_length` (maximum 291 values; 292 is accepted as a parseable malformed length).

For each message byte, process its bits from most significant to least significant. For each bit, visit the next row-major pixel and compute `pixel + (pixel_lsb XOR message_bit)`. This preserves the source's increment-only embedding rule: matching parity is unchanged and mismatching parity increments the pixel. Pixels after the message bits remain unchanged. Return all `rows * columns` resulting pixel values as raw bytes and return the pixel count. A null input, invalid dimensions/framing/domain, or a message that does not fit returns `-1`. Valid input with a null output buffer or capacity smaller than the pixel count returns `-2` without writing. Maximum output and workspace are 256 bytes.

Input values are restricted to 0..254 because the source stores the updated values in an 8-bit image; a value of 255 with an embedded zero bit would require incrementing beyond the representable range. The source silently stops embedding when the image runs out of pixels; this bounded contract instead rejects a message that does not fit so every accepted input embeds its full message. Empty messages are valid and return an unchanged copy of every pixel.

## Workload and oracle

[workload.json](workload.json) covers empty and nonempty messages, MSB-first bit order, no-op parity, NUL and high ASCII bytes, the maximum image/message, malformed framing/domain, insufficient pixel count, and null/short output. The independent byte-array oracle is [lsb_image_steganography_oracle.py](../../lsb_image_steganography_oracle.py).

## Implementations

| Language | Source |
| --- | --- |
| C | [c/i/lsb_image_steganography.c](../../../c/i/lsb_image_steganography.c) |
| C3 | [c3/i/lsb_image_steganography.c3](../../../c3/i/lsb_image_steganography.c3) |
| C++ | [cpp/i/lsb_image_steganography.cpp](../../../cpp/i/lsb_image_steganography.cpp) |
| Elisa | [elisa/i/lsb_image_steganography.elisa](../../../elisa/i/lsb_image_steganography.elisa) |
| Nim | [nim/i/lsb_image_steganography.nim](../../../nim/i/lsb_image_steganography.nim) |
| Odin | [odin/i/lsb_image_steganography.odin](../../../odin/i/lsb_image_steganography.odin) |
| Rust | [rust/i/lsb_image_steganography.rs](../../../rust/i/lsb_image_steganography.rs) |
| V | [v/i/lsb_image_steganography.v](../../../v/i/lsb_image_steganography.v) |
| Zig | [zig/i/lsb_image_steganography.zig](../../../zig/i/lsb_image_steganography.zig) |
