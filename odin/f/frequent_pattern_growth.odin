package frequent_pattern_growth

Context :: struct { minimum: i64, order: [8]int, result: i64 }

grow :: proc "contextless" (ctx: ^Context, masks, weights: [^]i64, length, rank_limit: int) {
	next_masks: [64]i64
	next_weights: [64]i64
	for rank := rank_limit - 1; rank >= 0; rank -= 1 {
		bit := i64(1) << u32(ctx.order[rank])
		support := i64(0)
		for i := 0; i < length; i += 1 { if (masks[i] & bit) != 0 do support += weights[i] }
		if support < ctx.minimum do continue
		ctx.result += 1
		ancestor := i64(0)
		for j := 0; j < rank; j += 1 { ancestor |= i64(1) << u32(ctx.order[j]) }
		next_len := 0
		for i := 0; i < length; i += 1 {
			if (masks[i] & bit) != 0 { next_masks[next_len] = masks[i] & ancestor; next_weights[next_len] = weights[i]; next_len += 1 }
		}
		grow(ctx, &next_masks[0], &next_weights[0], next_len, rank)
	}
}

@(export)
frequent_pattern_growth :: proc "c" (a: [^]i64, n: uintptr) -> i64 {
	if a == nil || n < 3 || n > 67 do return -1
	rows, items, minimum := a[0], a[1], a[2]
	if rows < 1 || rows > 64 || items < 1 || items > 8 || minimum < 1 || minimum > rows || n != uintptr(3 + rows) do return -1
	limit := i64(1) << u32(items);
	support: [8]i64
	masks: [64]i64
	weights: [64]i64
	for row := i64(0); row < rows; row += 1 {
		mask := a[uintptr(3 + row)]
		if mask < 0 || mask >= limit do return -1
	}
	ctx := Context{minimum = minimum}
	for row := i64(0); row < rows; row += 1 {
		masks[uintptr(row)] = a[uintptr(3 + row)]; weights[uintptr(row)] = 1
		for item := i64(0); item < items; item += 1 { if (masks[uintptr(row)] & (i64(1) << u32(item))) != 0 do support[uintptr(item)] += 1 }
	}
	for item := 0; item < int(items); item += 1 { ctx.order[item] = item }
	for i := 1; i < int(items); i += 1 {
		value := ctx.order[i]; j := i
		for j > 0 && (support[ctx.order[j - 1]] < support[value] || (support[ctx.order[j - 1]] == support[value] && ctx.order[j - 1] > value)) { ctx.order[j] = ctx.order[j - 1]; j -= 1 }
		ctx.order[j] = value
	}
	grow(&ctx, &masks[0], &weights[0], int(rows), int(items))
	return ctx.result
}
