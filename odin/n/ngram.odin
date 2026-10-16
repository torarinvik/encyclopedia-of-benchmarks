package ngram
import "core:c"
@(export)
ngram :: proc "c" (v: [^]i64, n: c.size_t, out: [^]u8, cap: c.size_t) -> i64 {
	if v == nil || n < 2 || n > 258 || v[0] < 1 || v[0] > 16 || v[1] < 0 || v[1] > 256 || n != c.size_t(v[1]) + 2 do return -1
	width := int(v[0]); text := int(v[1])
	for i := 0; i < text; i += 1 { if v[i + 2] < 32 || v[i + 2] > 126 do return -1 }
	grams := 0; if text >= width do grams = text - width + 1
	bytes := 0; if grams > 0 do bytes = grams * width + grams - 1
	if c.size_t(bytes) > cap || (bytes > 0 && out == nil) do return -2
	w := 0
	for i := 0; i < grams; i += 1 {
		if i > 0 { out[w] = 10; w += 1 }
		for j := 0; j < width; j += 1 { out[w] = u8(v[i + j + 2]); w += 1 }
	}
	return i64(w)
}
