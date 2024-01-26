const std = @import("std");

const test_image = @embedFile("example2.qoi");

const dprint  = std.debug.print;
const dassert = std.debug.assert;

const Qoi_Header = struct {
    magic_bytes  : [4] u8,
    image_width  : u32,
    image_height : u32,
    channel      : u8,
    colorspace   : u8,
};

pub fn main() void {
    // Parse the image header into the qoi_header struct.
    const raw_image = test_image;
    const qoi_header  = Qoi_Header{
        .magic_bytes  = [4]u8{raw_image[0], raw_image[1], raw_image[2], raw_image[3]},
        .image_width  = std.mem.readIntSlice(u32, raw_image[4..8],  .Big), // (Thanks tw0st3p!)
        .image_height = std.mem.readIntSlice(u32, raw_image[8..12], .Big),
        .channel      = raw_image[12],
        .colorspace   = raw_image[13],
    };

    // Check the magic bytes are correct for a .qoi file.
    const magic_bytes_match = std.mem.eql(u8, &qoi_header.magic_bytes, "qoif");
    dassert(magic_bytes_match);
    
    dprint("Header: {any}\n", .{qoi_header}); // @debug
}
