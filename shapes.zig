const rl     = @cImport(@cInclude("raylib.h"));

const Vec2   = @Vector(2, f32);
const Color = [4] u8;
const Pixel = [4] u8;

// Draw a plain (colored) rectangle, where the position determines the center.

pub fn draw_centered_rect( pos : Vec2, width : f32, height : f32, color : Color) void {
    const top_left_x : i32 = @intFromFloat(pos[0] - 0.5 * width);
    const top_left_y : i32 = @intFromFloat(pos[1] - 0.5 * height);
    rl.DrawRectangle(top_left_x, top_left_y, @intFromFloat(width), @intFromFloat(height), rlc(color));
}

// NOTE: Bloody raylib needs the point when drawing a triangle to be in
// a counter-clockwise direction,... so draw each triangle with both directions.
pub fn draw_triangle(p1 : Vec2, p2 : Vec2, p3 : Vec2, color : Color) void {
    
    const dumb_p1 = rl.Vector2{ .x = p1[0], .y = p1[1]};
    const dumb_p2 = rl.Vector2{ .x = p2[0], .y = p2[1]};
    const dumb_p3 = rl.Vector2{ .x = p3[0], .y = p3[1]};
    rl.DrawTriangle(dumb_p1, dumb_p2, dumb_p3, rlc(color));
    rl.DrawTriangle(dumb_p2, dumb_p1, dumb_p3, rlc(color));
}

fn rlc(color : Color) rl.Color {
    return rl.Color{.r = color[0], .g = color[1], .b = color[2], .a = color[3]};
}
