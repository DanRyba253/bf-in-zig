const std = @import("std");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "bf",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    const source_file_path = blk: {
        if (b.args) |args| if (args.len > 0) {
            break :blk args[0];
        };
        return error.MissingArgumentInputFile;
    };

    var source_file = try std.fs.cwd().openFile(source_file_path, .{
        .mode = .read_only,
    });
    defer source_file.close();

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const source = try source_file.readToEndAlloc(allocator, std.math.maxInt(usize));
    defer allocator.free(source);

    const options = b.addOptions();
    options.addOption([]const u8, "source", source);
    exe.root_module.addOptions("options", options);

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
