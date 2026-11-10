module trapped_rainwater_two_pointer

// Process the smaller endpoint, validating each bar as it enters the window.
@[export: 'trapped_rainwater_two_pointer']
pub fn trapped_rainwater_two_pointer(heights &i64, length usize) i64 {
    if length > 4096 || (length != 0 && unsafe { heights == nil }) { return -1 }
    if length == 0 { return 0 }

    mut left := usize(0)
    mut right := length - 1
    mut left_height := u64(unsafe { heights[left] })
    mut right_height := u64(unsafe { heights[right] })
    if left_height > 1000000 || right_height > 1000000 { return -1 }

    mut left_max := u32(0)
    mut right_max := u32(0)
    mut trapped := u32(0)
    for left < right {
        if left_height < right_height {
            height := u32(left_height)
            left_max = if height > left_max { height } else { left_max }
            trapped += left_max - height
            left++
            left_height = u64(unsafe { heights[left] })
            if left_height > 1000000 { return -1 }
        } else {
            height := u32(right_height)
            right_max = if height > right_max { height } else { right_max }
            trapped += right_max - height
            right--
            right_height = u64(unsafe { heights[right] })
            if right_height > 1000000 { return -1 }
        }
    }
    return i64(trapped)
}
