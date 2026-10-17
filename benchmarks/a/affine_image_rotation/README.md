# Affine image rotation

This benchmark specializes the pinned Python `get_rotation` method, which estimates a three-point affine transform and warps a grayscale image.

## Contract

- The ABI is `i32_array_bytes_output`. Input is signed-i32 words `[rows, cols, pixels..., pt1..., pt2...]`: row-major grayscale pixel values first, then three `(x,y)` pairs for `pt1`, followed by their three corresponding `(x,y)` pairs for `pt2`. Coordinates use `x=column`, `y=row`. The exact length is `14 + rows*cols`. Dimensions are 1–8, pixels are 0–255, and all point coordinates are integers in `[-16,16]`, converted exactly to the source's float32 coordinates. The maximum valid input is 78 words; one extra word is accepted only so malformed trailing data can be rejected.
- The three `pt1` points must be non-collinear. Their exact affine map to `pt2` must have integer coefficients `a,b,c,d` in `[-2,2]`, integer translations `tx,ty` in `[-16,16]`, and determinant `a*d-b*c` equal to `-1` or `1`. Each point pair must satisfy `x' = a*x + b*y + tx` and `y' = c*x + d*y + ty`. These bounds keep every inverse-mapped output coordinate on the integer pixel lattice, so the source's default linear interpolation samples exact pixels.
- The source calls `cv2.warpAffine(img, matrix, (rows, cols))`. OpenCV treats that tuple as `(width,height)`, so output shape is `(cols, rows)`, even though the input shape is `(rows, cols)`. Output is raw row-major grayscale bytes; out-of-bounds samples use the source's default constant-zero border. Success returns `rows*cols` bytes, from 1 through 64.
- Invalid shape, dimensions, pixels, coordinates, degenerate source points, or affine maps return `-1` before output checks. A null output pointer or insufficient capacity returns `-2` without writes.

The workload includes identity on a rectangular image to expose the `(rows,cols)` destination-size behavior, a quarter turn, integer shears, translations, reflections, border fill, invalid geometry and domain values, and output-capacity cases. See [workload.json](workload.json) and the independent [oracle](../../affine_image_rotation_oracle.py).

The source is Python [`get_rotation`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/digital_image_processing/rotation/rotation.py), pinned at commit `e1a2a8b016001309a73d5fec4818c35cca139795`. It calls `cv2.getAffineTransform(pt1, pt2)` and then `cv2.warpAffine(img, matrix, (rows, cols))` with OpenCV's default interpolation and border settings.

## Reproduce

~~~
python3 benchmarks/build_abi.py --family i32_array_bytes_output --algorithm affine_image_rotation --language rust
python3 benchmarks/run_i32_array_bytes_output.py --algorithm affine_image_rotation
python3 benchmarks/verify_i32_array_bytes_output.py --algorithm affine_image_rotation --languages rust
~~~

## Language ports

- C: [c/a/affine_image_rotation.c](../../../c/a/affine_image_rotation.c)
- C3: [c3/a/affine_image_rotation.c3](../../../c3/a/affine_image_rotation.c3)
- C++: [cpp/a/affine_image_rotation.cpp](../../../cpp/a/affine_image_rotation.cpp)
- Elisa: [elisa/a/affine_image_rotation.elisa](../../../elisa/a/affine_image_rotation.elisa)
- Nim: [nim/a/affine_image_rotation.nim](../../../nim/a/affine_image_rotation.nim)
- Odin: [odin/a/affine_image_rotation.odin](../../../odin/a/affine_image_rotation.odin)
- Rust: [rust/a/affine_image_rotation.rs](../../../rust/a/affine_image_rotation.rs)
- V: [v/a/affine_image_rotation.v](../../../v/a/affine_image_rotation.v)
- Zig: [zig/a/affine_image_rotation.zig](../../../zig/a/affine_image_rotation.zig)
