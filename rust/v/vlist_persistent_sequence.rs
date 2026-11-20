use core::slice;

const MAX_Q: usize = 48;
const MAX_CONS: i32 = 32;
const MAX_ROOTS: usize = 49;
const MAX_BLOCKS: usize = 6;
const MAX_SLOTS: usize = 63;
const MAX_PARSEABLE: usize = 146;

#[derive(Clone, Copy, Default)]
struct Block {
    previous_block: i32,
    previous_offset: i32,
    capacity: i32,
    last_used: i32,
    base: i32,
}

struct Context {
    blocks: [Block; MAX_BLOCKS],
    data: [i64; MAX_SLOTS],
    root_block: [i32; MAX_ROOTS],
    root_offset: [i32; MAX_ROOTS],
    results: [i64; MAX_Q],
    block_count: i32,
    root_count: i32,
    slot_count: i32,
    cons_count: i32,
}

impl Context {
    fn new() -> Self {
        Self {
            blocks: [Block::default(); MAX_BLOCKS],
            data: [0; MAX_SLOTS],
            root_block: [-1; MAX_ROOTS],
            root_offset: [-1; MAX_ROOTS],
            results: [0; MAX_Q],
            block_count: 0,
            root_count: 1,
            slot_count: 0,
            cons_count: 0,
        }
    }

    fn length(&self, root: usize) -> Option<i64> {
        let mut block_id = self.root_block[root];
        let mut offset = self.root_offset[root];
        let mut total = 0_i64;
        while block_id >= 0 {
            if block_id >= self.block_count { return None; }
            let block = self.blocks[block_id as usize];
            if offset < 0 || offset > block.last_used { return None; }
            total += i64::from(offset) + 1;
            block_id = block.previous_block;
            offset = block.previous_offset;
        }
        Some(total)
    }

    fn nth(&self, root: usize, index: i64) -> Option<i64> {
        let mut block_id = self.root_block[root];
        let mut offset = self.root_offset[root];
        let mut remaining = index;
        while block_id >= 0 {
            if block_id >= self.block_count { return None; }
            let block = self.blocks[block_id as usize];
            if offset < 0 || offset > block.last_used { return None; }
            if remaining <= i64::from(offset) {
                let position = block.base + offset - remaining as i32;
                return Some(self.data[position as usize]);
            }
            remaining -= i64::from(offset) + 1;
            block_id = block.previous_block;
            offset = block.previous_offset;
        }
        None
    }
}

unsafe fn store_i64_le(output: *mut u8, byte_offset: usize, value: i64) {
    let bytes = value.to_le_bytes();
    for (i, byte) in bytes.iter().enumerate() {
        unsafe { *output.add(byte_offset + i) = *byte; }
    }
}

#[no_mangle]
pub unsafe extern "C" fn vlist_persistent_sequence(
    input: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if input.is_null() || length < 1 || length > MAX_PARSEABLE { return -1; }
    let values = unsafe { slice::from_raw_parts(input, length) };
    let q_word = values[0];
    if !(1..=MAX_Q as i64).contains(&q_word) || length != 1 + 3 * q_word as usize { return -1; }
    let q = q_word as usize;
    let mut ctx = Context::new();
    let mut query_phase = false;
    let mut at = 1;
    for op in 0..q {
        let tag = values[at];
        let root_word = values[at + 1];
        let arg = values[at + 2];
        at += 3;
        if !(0..=3).contains(&tag) || root_word < 0 || root_word >= i64::from(ctx.root_count) { return -1; }
        let root = root_word as usize;
        if tag == 0 {
            if query_phase || root_word != i64::from(ctx.root_count - 1) ||
                ctx.cons_count >= MAX_CONS || !(-1_000_000..=1_000_000).contains(&arg) { return -1; }
            let mut block_id = ctx.root_block[root];
            let mut offset = ctx.root_offset[root];
            if block_id < 0 {
                if ctx.cons_count != 0 || ctx.block_count != 0 || ctx.slot_count >= MAX_SLOTS as i32 { return -1; }
                let block = &mut ctx.blocks[ctx.block_count as usize];
                block.previous_block = -1;
                block.previous_offset = -1;
                block.capacity = 1;
                block.last_used = 0;
                block.base = ctx.slot_count;
                ctx.data[block.base as usize] = arg;
                ctx.slot_count += 1;
                block_id = ctx.block_count;
                ctx.block_count += 1;
                offset = 0;
            } else {
                if block_id >= ctx.block_count || offset != ctx.blocks[block_id as usize].last_used { return -1; }
                let capacity = ctx.blocks[block_id as usize].capacity;
                if offset + 1 < capacity {
                    offset += 1;
                    let block = ctx.blocks[block_id as usize];
                    ctx.data[(block.base + offset) as usize] = arg;
                    ctx.blocks[block_id as usize].last_used = offset;
                } else {
                    let next_capacity = capacity * 2;
                    if ctx.block_count >= MAX_BLOCKS as i32 || ctx.slot_count + next_capacity > MAX_SLOTS as i32 { return -1; }
                    let next_id = ctx.block_count as usize;
                    let next_base = ctx.slot_count;
                    ctx.blocks[next_id] = Block {
                        previous_block: block_id,
                        previous_offset: offset,
                        capacity: next_capacity,
                        last_used: 0,
                        base: next_base,
                    };
                    ctx.data[next_base as usize] = arg;
                    ctx.slot_count += next_capacity;
                    block_id = ctx.block_count;
                    ctx.block_count += 1;
                    offset = 0;
                }
            }
            if ctx.root_count >= MAX_ROOTS as i32 { return -1; }
            let new_root = ctx.root_count as usize;
            ctx.root_block[new_root] = block_id;
            ctx.root_offset[new_root] = offset;
            ctx.results[op] = i64::from(ctx.root_count);
            ctx.root_count += 1;
            ctx.cons_count += 1;
        } else {
            query_phase = true;
            if tag == 1 {
                if arg != -1 || ctx.length(root).unwrap_or(-1) <= 0 { return -1; }
                let mut block_id = ctx.root_block[root];
                let mut offset = ctx.root_offset[root];
                if offset > 0 {
                    offset -= 1;
                } else {
                    let block = ctx.blocks[block_id as usize];
                    block_id = block.previous_block;
                    offset = block.previous_offset;
                }
                if ctx.root_count >= MAX_ROOTS as i32 { return -1; }
                let new_root = ctx.root_count as usize;
                ctx.root_block[new_root] = block_id;
                ctx.root_offset[new_root] = offset;
                ctx.results[op] = i64::from(ctx.root_count);
                ctx.root_count += 1;
            } else if tag == 2 {
                let n = ctx.length(root).unwrap_or(-1);
                if n < 0 || arg < 0 || arg >= n { return -1; }
                ctx.results[op] = ctx.nth(root, arg).ok_or(()).unwrap_or(i64::MIN);
                if ctx.results[op] == i64::MIN { return -1; }
            } else {
                if arg != -1 { return -1; }
                let n = ctx.length(root).unwrap_or(-1);
                if n < 0 { return -1; }
                ctx.results[op] = n;
            }
        }
    }
    let bytes = q * 8;
    if output.is_null() || capacity < bytes { return -2; }
    for i in 0..q {
        unsafe { store_i64_le(output, i * 8, ctx.results[i]); }
    }
    bytes as i64
}
