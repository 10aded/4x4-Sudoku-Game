const std = @import("std");

const test_image = @embedFile("QOI-Tests/3x4.qoi");

fn dprint(comptime fmt: []const u8, args: anytype) void {
    if(@inComptime()) {
        // uncomment to debug at comptime
        // @compileLog(std.fmt.comptimePrint(fmt, args));
    } else {
        std.debug.print(fmt, args);
    }
}
const dassert = std.debug.assert;

const Pixel = [4] u8;

const Qoi_Header = struct {
    magic_bytes  : [4] u8,
    image_width  : u32,
    image_height : u32,
    channel      : u8,
    colorspace   : u8,
};

// Note: In Zig DEBUG builds, static memory that are set to undefined are 
// filled with 0xaa s.

pub fn parse_header( reader: anytype ) !Qoi_Header {
        // Parse the image header into the qoi_header struct.
    
    const qoi_header  = Qoi_Header{
        .magic_bytes  = try reader.readBytesNoEof(4),
        .image_width  = try reader.readInt(u32, .Big), // (Thanks tw0st3p!)
        .image_height = try reader.readInt(u32, .Big),
        .channel      = try reader.readByte(),
        .colorspace   = try reader.readByte(),
    };

    // Check the magic bytes are correct for a .qoi file.
    const magic_bytes_match = std.mem.eql(u8, &qoi_header.magic_bytes, "qoif");
    dassert(magic_bytes_match);
    
    return qoi_header;
}


// In the enum below, the OP XYZ refers to QOI_OP_XYZ in the specification.
const QOI_OPS = enum(u8) {
    RGB,
    RGBA,
    INDEX,
    DIFF,
    LUMA,
    RUN,
};

// @decision: Should this procedure take in a pixel array that is a matrix
// or a simple array... I feel like it should actually just be an array.
pub fn qoi_to_pixels( reader : anytype, header : Qoi_Header, writer : anytype ) !void {
    // Per the specification,
    // "The decoder and encoder start with {r: 0, g: 0, b: 0, a: 255} as the
    //previous pixel value."
    var current_pixel = Pixel{0,0,0,255};
    
    // @question: Does Zig zero-init arrays by default?
    var previously_seen_pixels : [64] Pixel = undefined;
    previously_seen_pixels[0] = Pixel{0,0,0,0};

    var current_pixel_index : usize = 0;
    while( current_pixel_index < header.image_width * header.image_height ) : ( current_pixel_index += 1 ) {
        const current_byte = try reader.readByte();
        const bits_67     : u2 = @truncate(current_byte >> 6);
        const bits_012345 : u6 = @truncate(current_byte & 0b00111111);
        const current_qoi_op: QOI_OPS = switch (bits_67) {
            0b00 => .INDEX,
            0b01 => .DIFF,
            0b10 => .LUMA,
            0b11 => switch(bits_012345) {
                0b111110 => .RGB,
                0b111111 => .RGBA,
                else     => .RUN,
            },
        };
        dprint("Current OP: {any}\n", .{current_qoi_op});

        // Calculate the next pixel(s) values, and the index advances.
        
        switch (current_qoi_op) {
            .RGB => {
                // Read a RGB value from the file.
                const rgb = try reader.readBytesNoEof(3);
                current_pixel = rgb ++ [1]u8{current_pixel[3]};
            },
            .RGBA => {
                // Read a RGBA value from the file.
                current_pixel = try reader.readBytesNoEof(4);
            },
            .INDEX => {
                // Lookup a pixel in previously_seen_pixels, using first six bits
                // of the current byte.
                const index = @as(usize, bits_012345);
                current_pixel = previously_seen_pixels[index];
            },
            .DIFF => {
                const dr : u2 = @truncate(bits_012345 >> 4);
                const dg : u2 = @truncate(bits_012345 >> 2);
                const db : u2 = @truncate(bits_012345 >> 0); // @bugwatch (!)
                // The specification (regularly) assumes wrapping subtraction,
                // hence the wrapping subtraction here.
                current_pixel = Pixel{current_pixel[0] +% dr -% 2,
                                      current_pixel[1] +% dg -% 2,
                                      current_pixel[2] +% db -% 2,
                                      current_pixel[3]};
            },
            .LUMA => {
                // Get bits.
                var diff_green : u8 = @as(u8, bits_012345);
                const drdb_byte = try reader.readByte();
                var drdg : u8 = drdb_byte >> 4; // This should be filled with 0s.
                var dbdg : u8 = drdb_byte & 0x0F;
                // Apply offsets.
                diff_green -%= 32;
                drdg       -%= 8;
                dbdg       -%= 8;
                const dg = diff_green;
                const dr = diff_green +% drdg;
                const db = diff_green +% dbdg;
                current_pixel = Pixel{current_pixel[0] +% dr,
                                      current_pixel[1] +% dg,
                                      current_pixel[2] +% db,
                                      current_pixel[3]};
            },
            .RUN => {
                // Unlike the other OPS, which only write a single
                // pixel, this one writes many (by repeating the value
                // of the current pixel), so the code is a bit different here.
                var run = @as(usize, bits_012345);
                run += 1;

                // Note: Setting this after the loop would mean that
                // the advance is 0, which we don't want. (thanks tw0st3p)!
                
                while (run != 0) : (run -= 1) {
                    _ = try writer.write(&current_pixel);
                    current_pixel_index += 1;
                }
                continue;
            },
        }
        _ = try writer.write(&current_pixel);
        
        
        // We don't need to hash when the OP is one of:
        // .RUN
        // .INDEX
        
        // We need to hash a pixel (and store in the previously_seen_pixels)
        // when the OP is one of:
        // .RGB
        // .RGBA
        // .DIFF
        // .LUMA (since the op is 2 bytes, but a INDEX op is just 1 byte)

        // Note: For .DIFF, the specification doesn't say
        // when encoding whether or not .INDEX should have a higher priority
        // than (e.g.) .DIFF
        // As such, hashing a .DIFF result may be reduntant, but we'll choose
        // to do so anyway.
        // This could be because .INDEX should always be chosen if a pixel has
        // been seen before, except in the case of two consecutive INDEXs
        // (in which case a run would be issued instead).

        var hash : u8 = undefined;
        switch(current_qoi_op) {
            .RUN, .INDEX  => {},
            .RGB, .RGBA, .DIFF, .LUMA  => {
                hash = pixel_hash(current_pixel);
                previously_seen_pixels[hash] = current_pixel;
            },
        }
        
        // @debug
        dprint("{any}\n", .{current_pixel});
    }
}

fn pixel_hash(pixel : Pixel) u6 {
    const r = pixel[0];
    const g = pixel[1];
    const b = pixel[2];
    const a = pixel[3];
    // Using only * will result in a runtime panic: integer overflow
    // To avoid this, we use *% instead. (@thanks tw0st3p!)
    const hash : u6 = @truncate(r *% 3 +% g *% 5 +% b *% 7 +% a *% 11);
    return hash;
}

fn print_pixels(pixels: []const u8) void {
    var pxi : usize = 0;
    while(pxi < pixels.len) : (pxi += 4) {
        dprint("#{x:0>2}{x:0>2}{x:0>2}{x:0>2}\n", .{pixels[pxi], pixels[pxi + 1], pixels[pxi + 2], pixels[pxi + 3]});
    }
}

pub fn main() !void {
    // TODO: Turn the following into a Zig test
    // Suggestion (tw0st3p:
    // test "test name" { std.testing.expectEqual(@as(u8, 69, foo())) };
    //    const test_pixel_hash = pixel_hash(Pixel{1,1,1,1});
    // Expect: 22
//    const test_pixel_hash = pixel_hash(Pixel{100,0,0,0});
    // Expect: 44
//    dprint("PH: {d}\n", .{test_pixel_hash}); // @debug
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var fbs = std.io.fixedBufferStream(test_image);
    const test_image_header = try parse_header(fbs.reader());
    var test_image_pixels = try allocator.alloc(u8, test_image_header.image_width * test_image_header.image_height * 4);
    defer allocator.free(test_image_pixels);

    var fbs2 = std.io.fixedBufferStream(test_image_pixels);
    try qoi_to_pixels(fbs.reader(), test_image_header, fbs2.writer());

    dprint("Header: {any}\n", .{test_image_header}); // @debug
    print_pixels(test_image_pixels);
}

// This can be run on its own with the command:
//
//     zig test qoi.zig --test-filter "comptime parse"
//
test "comptime parse" {
   const pixels = comptime blk: {
        var fbs = std.io.fixedBufferStream(test_image);
        const test_image_header = try parse_header(fbs.reader());
        var test_image_pixels: [test_image_header.image_width * test_image_header.image_height * 4] u8 = undefined;

        var fbs2 = std.io.fixedBufferStream(&test_image_pixels);
        try qoi_to_pixels(fbs.reader(), test_image_header, fbs2.writer());
        break :blk test_image_pixels;
    };

    print_pixels(&pixels);
}
