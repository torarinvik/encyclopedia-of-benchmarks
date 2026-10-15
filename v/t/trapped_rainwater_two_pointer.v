module trapped_rainwater_two_pointer

const max_length = 4096

// Sum trapped water by advancing the side with the smaller current boundary.
@[export: 'trapped_rainwater_two_pointer']
pub fn trapped_rainwater_two_pointer(heights &i64, length usize) i64 {
	if length > max_length || (length > 0 && unsafe { heights == nil }) { return -1 }
	unsafe {
		for index in 0 .. length {
			if heights[index] < 0 || heights[index] > 1000000 { return -1 }
		}
		if length <= 2 { return 0 }

		mut left := usize(0)
		mut right := length - 1
		mut left_max := u32(0)
		mut right_max := u32(0)
		mut trapped := u32(0)
		for left < right {
			if heights[left] < heights[right] {
				height := u32(heights[left])
				if height >= left_max { left_max = height } else { trapped += left_max - height }
				left++
			} else {
				height := u32(heights[right])
				if height >= right_max { right_max = height } else { trapped += right_max - height }
				right--
			}
		}
		return i64(trapped)
	}
}
