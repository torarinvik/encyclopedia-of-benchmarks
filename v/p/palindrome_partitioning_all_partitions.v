module palindrome_partitioning_all_partitions

const max_length = 12
const out_cap = 16000
struct Context {
	text [max_length]i64
	length int
	ends [max_length]int
	packed [out_cap]i64
	mut:
	used int
	partitions int
}

fn is_palindrome(ctx &Context, start int, finish int) bool {
	mut left := start
	mut right := finish
	for left < right {
		if ctx.text[left] != ctx.text[right - 1] { return false }
		left++
		right--
	}
	return true
}

fn enumerate(mut ctx Context, start int, depth int) {
	if start == ctx.length {
		ctx.partitions++
		ctx.packed[ctx.used] = i64(depth)
		ctx.used++
		for i in 0 .. depth { ctx.packed[ctx.used] = i64(ctx.ends[i]); ctx.used++ }
		return
	}
	for finish := start + 1; finish <= ctx.length; finish++ {
		if is_palindrome(ctx, start, finish) {
			ctx.ends[depth] = finish
			enumerate(mut ctx, finish, depth + 1)
		}
	}
}

@[export: 'palindrome_partitioning_all_partitions']
pub fn palindrome_partitioning_all_partitions(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 1 { return -1 }
	unsafe {
		if input[0] < 0 || input[0] > max_length || length != usize(input[0]) + 1 { return -1 }
		mut ctx := Context{length: int(input[0]), used: 1}
		for i in 0 .. ctx.length {
			if input[i + 1] < 0 || input[i + 1] > 127 { return -1 }
			ctx.text[i] = input[i + 1]
		}
		enumerate(mut ctx, 0, 0)
		ctx.packed[0] = i64(ctx.partitions)
		needed := ctx.used * 8
		if output == nil || capacity < needed { return -2 }
		for i in 0 .. ctx.used {
			bits := u64(ctx.packed[i])
			for byte in 0 .. 8 { output[i * 8 + byte] = u8(bits >> (8 * byte)) }
		}
		return i64(needed)
	}
}
