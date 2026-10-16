module frequent_pattern_growth

struct GrowthContext {
	minimum i64
	mut:
	order [8]int
	result i64
}

fn grow(mut ctx GrowthContext, masks []i64, weights []i64, rank_limit int) {
	for rank := rank_limit - 1; rank >= 0; rank-- {
		bit := i64(1) << u32(ctx.order[rank])
	mut support := i64(0)
		for i in 0 .. masks.len { if (masks[i] & bit) != 0 { support += weights[i] } }
		if support < ctx.minimum { continue }
		ctx.result++
		mut ancestor := i64(0)
		for r in 0 .. rank { ancestor |= i64(1) << u32(ctx.order[r]) }
		mut next_masks := []i64{}
		mut next_weights := []i64{}
		for i in 0 .. masks.len { if (masks[i] & bit) != 0 { next_masks << (masks[i] & ancestor); next_weights << weights[i] } }
		grow(mut ctx, next_masks, next_weights, rank)
	}
}

@[export: 'frequent_pattern_growth']
pub fn frequent_pattern_growth(a &i64, length usize) i64 {
	if isnil(a) || length < 3 || length > 67 { return -1 }
	rows := unsafe { a[0] }
	items := unsafe { a[1] }
	minimum := unsafe { a[2] }
	if rows < 1 || rows > 64 || items < 1 || items > 8 || minimum < 1 || minimum > rows || length != usize(3 + rows) { return -1 }
	limit := i64(1) << u32(items)
	for row in 0 .. int(rows) {
		mask := unsafe { a[3 + row] }
		if mask < 0 || mask >= limit { return -1 }
	}
	mut ctx := GrowthContext{minimum: minimum}
	mut support := [8]i64{}
	mut masks := []i64{}
	mut weights := []i64{}
	for row in 0 .. int(rows) {
		mask := unsafe { a[3 + row] }; masks << mask; weights << 1
		for item in 0 .. int(items) { if (mask & (i64(1) << u32(item))) != 0 { support[item]++ } }
	}
	for item in 0 .. int(items) { ctx.order[item] = item }
	for i in 1 .. int(items) {
		value := ctx.order[i]; mut j := i
		for j > 0 && (support[ctx.order[j - 1]] < support[value] || (support[ctx.order[j - 1]] == support[value] && ctx.order[j - 1] > value)) { ctx.order[j] = ctx.order[j - 1]; j-- }
		ctx.order[j] = value
	}
	grow(mut ctx, masks, weights, int(items))
	return ctx.result
}
