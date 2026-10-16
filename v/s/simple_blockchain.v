module simple_blockchain

const max_input = 4096
const max_padded = 4160
const k = [64]u32{0x428a2f98,0x71374491,0xb5c0fbcf,0xe9b5dba5,0x3956c25b,0x59f111f1,0x923f82a4,0xab1c5ed5,0xd807aa98,0x12835b01,0x243185be,0x550c7dc3,0x72be5d74,0x80deb1fe,0x9bdc06a7,0xc19bf174,0xe49b69c1,0xefbe4786,0x0fc19dc6,0x240ca1cc,0x2de92c6f,0x4a7484aa,0x5cb0a9dc,0x76f988da,0x983e5152,0xa831c66d,0xb00327c8,0xbf597fc7,0xc6e00bf3,0xd5a79147,0x06ca6351,0x14292967,0x27b70a85,0x2e1b2138,0x4d2c6dfc,0x53380d13,0x650a7354,0x766a0abb,0x81c2c92e,0x92722c85,0xa2bfe8a1,0xa81a664b,0xc24b8b70,0xc76c51a3,0xd192e819,0xd6990624,0xf40e3585,0x106aa070,0x19a4c116,0x1e376c08,0x2748774c,0x34b0bcb5,0x391c0cb3,0x4ed8aa4a,0x5b9cca4f,0x682e6ff3,0x748f82ee,0x78a5636f,0x84c87814,0x8cc70208,0x90befffa,0xa4506ceb,0xbef9a3f7,0xc67178f2}
fn rotr(x u32, n u32) u32 { return (x >> n) | (x << (32 - n)) }
fn add32(a u32, b u32) u32 { return u32((u64(a) + u64(b)) & 0xffffffff) }

fn bc_sha256(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if length > max_input { return -1 }
	unsafe {
		if length > 0 && input == nil { return -1 }
		for i in 0 .. int(length) { if input[i] < 0 || input[i] > 255 { return -1 } }
		mut padded := [max_padded]u8{}
		for i in 0 .. int(length) { padded[i] = u8(input[i]) }
		padded[length] = 0x80
		blocks := (length + 9 + 63) / 64
		padded_length := blocks * 64
		bit_length := u64(length) * 8
		for i in 0 .. 8 { padded[padded_length - 1 - i] = u8((bit_length >> (8 * i)) & 255) }
		mut h := [8]u32{0x6a09e667,0xbb67ae85,0x3c6ef372,0xa54ff53a,0x510e527f,0x9b05688c,0x1f83d9ab,0x5be0cd19}
		for block in 0 .. blocks {
			mut w := [64]u32{}
			for i in 0 .. 16 { p := block * 64 + i * 4; w[i] = (u32(padded[p]) << 24) | (u32(padded[p+1]) << 16) | (u32(padded[p+2]) << 8) | u32(padded[p+3]) }
			for i in 16 .. 64 { x := w[i-15]; y := w[i-2]; s0 := rotr(x,7) ^ rotr(x,18) ^ (x >> 3); s1 := rotr(y,17) ^ rotr(y,19) ^ (y >> 10); w[i] = add32(add32(add32(s1,w[i-7]),s0),w[i-16]) }
			mut a := h[0]; mut b := h[1]; mut c := h[2]; mut d := h[3]; mut e := h[4]; mut f := h[5]; mut g := h[6]; mut hh := h[7]
			for i in 0 .. 64 {
				s1 := rotr(e,6) ^ rotr(e,11) ^ rotr(e,25); ch := (e & f) ^ ((~e) & g)
				t1 := add32(add32(add32(add32(hh,s1),ch),k[i]),w[i])
				s0 := rotr(a,2) ^ rotr(a,13) ^ rotr(a,22); maj := (a & b) ^ (a & c) ^ (b & c); t2 := add32(s0,maj)
				hh=g;g=f;f=e;e=add32(d,t1);d=c;c=b;b=a;a=add32(t1,t2)
			}
			h[0]=add32(h[0],a);h[1]=add32(h[1],b);h[2]=add32(h[2],c);h[3]=add32(h[3],d);h[4]=add32(h[4],e);h[5]=add32(h[5],f);h[6]=add32(h[6],g);h[7]=add32(h[7],hh)
		}
		if output == nil || capacity < 32 { return -2 }
		for i in 0 .. 8 { for byte in 0 .. 4 { output[i*4+byte] = u8((h[i] >> (24 - 8 * byte)) & 255) } }
		return 32
	}
}


const bc_max_values = 465
const bc_max_chain = 8
const bc_max_data = 64
const bc_max_header = 160
const bc_nonce_attempts = 4096
const bc_max_output = 728

struct Block {
mut:
    timestamp_sec i64
    data [64]u8
    data_length int
    previous_hash [64]u8
    previous_hash_length int
    nonce i64
    hash [64]u8
}

fn bc_append_decimal(mut buffer [160]i64, position_value int, value_value i64) int {
    mut digits := [20]i64{}
    mut count := 0
    mut value := value_value
    for {
        digits[count] = 48 + value % 10
        count++
        value /= 10
        if value == 0 { break }
    }
    mut position := position_value
    for count > 0 {
        count--
        buffer[position] = digits[count]
        position++
    }
    return position
}

fn bc_make_header(index int, block Block, nonce i64, mut header [160]i64) int {
    mut length := bc_append_decimal(mut header, 0, i64(index))
    length = bc_append_decimal(mut header, length, block.timestamp_sec)
    header[length] = 46; length++
    header[length] = 48; length++
    for i in 0 .. block.data_length {
        header[length] = i64(block.data[i]); length++
    }
    for i in 0 .. block.previous_hash_length {
        header[length] = i64(block.previous_hash[i]); length++
    }
    return bc_append_decimal(mut header, length, nonce)
}

fn bc_to_hex(digest [32]u8, mut output [64]u8) {
    hex := "0123456789abcdef".bytes()
    for i in 0 .. 32 {
        byte := digest[i]
        output[2*i] = hex[byte >> 4]
        output[2*i+1] = hex[byte & 15]
    }
}

fn bc_compute_hash(index int, block Block, nonce i64, mut output [64]u8) bool {
    mut header := [160]i64{}
    mut digest := [32]u8{}
    length := bc_make_header(index, block, nonce, mut header)
    if bc_sha256(&header[0], usize(length), mut digest[0], 32) != 32 { return false }
    bc_to_hex(digest, mut output)
    return true
}

fn bc_has_prefix(hash [64]u8, difficulty i64) bool {
    for i in 0 .. int(difficulty) {
        if hash[i] != 48 { return false }
    }
    return true
}

fn bc_is_valid(blocks [8]Block, chain_length int, difficulty i64) bool {
    for i in 1 .. chain_length {
        if blocks[i].previous_hash_length != 64 { return false }
        for j in 0 .. 64 {
            if blocks[i].previous_hash[j] != blocks[i-1].hash[j] { return false }
        }
        if !bc_has_prefix(blocks[i].hash, difficulty) { return false }
        mut recomputed := [64]u8{}
        if !bc_compute_hash(i, blocks[i], blocks[i].nonce, mut recomputed) { return false }
        for j in 0 .. 64 {
            if blocks[i].hash[j] != recomputed[j] { return false }
        }
    }
    return true
}

fn bc_write_i64(mut output &u8, position_value int, value i64) int {
    mut position := position_value
    bits := u64(value)
    for i in 0 .. 8 {
        unsafe { output[position] = u8((bits >> (8*i)) & 255) }
        position++
    }
    return position
}

@[export: 'simple_blockchain']
pub fn simple_blockchain(input &i64, length usize, mut output &u8, output_capacity usize) i64 {
    if input == nil || length < 3 || length > bc_max_values { return -1 }
    mut values := []i64{len: int(length)}
    unsafe {
        for i in 0 .. int(length) { values[i] = input[i] }
    }
    difficulty := values[0]
    chain_length_value := values[1]
    if difficulty < 1 || difficulty > 2 || chain_length_value < 1 || chain_length_value > bc_max_chain { return -1 }
    chain_length := int(chain_length_value)
    max_timestamp := i64(2147483647)
    if values[2] < 0 || values[2] > max_timestamp { return -1 }

    mut blocks := [8]Block{}
    blocks[0].timestamp_sec = values[2]
    genesis := [13]u8{71,101,110,101,115,105,115,32,66,108,111,99,107}
    for i in 0 .. 13 { blocks[0].data[i] = genesis[i] }
    blocks[0].data_length = 13
    blocks[0].previous_hash[0] = 48
    blocks[0].previous_hash_length = 1

    mut cursor := 3
    for i in 1 .. chain_length {
        if cursor + 2 > values.len { return -1 }
        timestamp_sec := values[cursor]
        data_length_value := values[cursor+1]
        cursor += 2
        if timestamp_sec < 0 || timestamp_sec > max_timestamp || data_length_value < 0 || data_length_value > bc_max_data { return -1 }
        data_length := int(data_length_value)
        if cursor + data_length > values.len { return -1 }
        blocks[i].timestamp_sec = timestamp_sec
        blocks[i].data_length = data_length
        for j in 0 .. data_length {
            value := values[cursor+j]
            if value < 0 || value > 127 { return -1 }
            blocks[i].data[j] = u8(value)
        }
        cursor += data_length
    }
    if cursor != values.len { return -1 }

    for i in 0 .. chain_length {
        if i > 0 {
            for j in 0 .. 64 { blocks[i].previous_hash[j] = blocks[i-1].hash[j] }
            blocks[i].previous_hash_length = 64
        }
        mut mined := false
        for nonce in 0 .. bc_nonce_attempts {
            mut candidate := [64]u8{}
            if !bc_compute_hash(i, blocks[i], i64(nonce), mut candidate) { return -1 }
            if bc_has_prefix(candidate, difficulty) {
                blocks[i].nonce = i64(nonce)
                blocks[i].hash = candidate
                mined = true
                break
            }
        }
        if !mined { return -3 }
    }

    valid := if bc_is_valid(blocks, chain_length, difficulty) { i64(1) } else { i64(0) }
    mut payload := [bc_max_output]u8{}
    mut written := 0
    written = bc_write_i64(mut payload[0], written, 0)
    written = bc_write_i64(mut payload[0], written, chain_length_value)
    for i in 0 .. chain_length {
        written = bc_write_i64(mut payload[0], written, i64(i))
        written = bc_write_i64(mut payload[0], written, blocks[i].timestamp_sec)
        written = bc_write_i64(mut payload[0], written, blocks[i].nonce)
        for j in 0 .. 64 { payload[written] = blocks[i].hash[j]; written++ }
    }
    written = bc_write_i64(mut payload[0], written, valid)
    if output == nil || output_capacity < usize(written) { return -2 }
    unsafe {
        for i in 0 .. written { output[i] = payload[i] }
    }
    return i64(written)
}
