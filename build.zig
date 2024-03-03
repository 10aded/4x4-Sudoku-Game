const std    = @import("std");


// TODO:
// Remove the line below.
const raySdk = @import("Raylib5/src/build.zig");


// If imports in higher directories fail, try:
// exe.main_mod_path = ".";


pub fn build(b: *std.Build) void {
	const target = b.standardTargetOptions(.{});

	const optimize = b.standardOptimizeOption(.{});

	const exe = b.addExecutable(.{
		.name = "4x4-Sudoku",
		.root_source_file = .{ .path = "main.zig" },
		.target = target,
		.optimize = optimize,
	});

	b.installArtifact(exe);

    // TODO: Copy / modify the needed build code from the raylib build.zig file.
    var raylib = raySdk.addRaylib(b, target, optimize, .{});
    


    
	exe.addIncludePath(.{ .path = "Raylib5/src" });
	exe.linkLibrary(raylib);

	const run_cmd = b.addRunArtifact(exe);

	run_cmd.step.dependOn(b.getInstallStep());

	if (b.args) |args| {
		run_cmd.addArgs(args);
	}

	const run_step = b.step("run", "run the game");
	run_step.dependOn(&run_cmd.step);
}
