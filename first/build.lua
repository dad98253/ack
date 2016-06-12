local function objdir(e)
	return concatpath("$(OBJDIR)", cwd(), e.name)
end

definerule("normalrule",
	{
		ins = { type="targets" },
		outleaves = { type="strings" },
		label = { type="string", optional=true },
		objdir = { type="string", optional=true },
		commands = { type="strings" },
		vars = { type="table", default={} },
	},
	function (e)
		local dir = e.objdir or objdir(e)
		local realouts = {}
		for k, v in pairs(e.outleaves) do
			realouts[k] = concatpath(dir, v)
		end

		local vars = inherit(e.vars, {
			dir = dir
		})

		local result = simplerule {
			name = e.name,
			ins = e.ins,
			outs = realouts,
			label = e.label,
			commands = e.commands,
			vars = vars,
		}
		result.dir = dir
		return result
	end
)

definerule("cfile",
	{
		srcs = { type="targets" },
		deps = { type="targets", default={} },
		cflags = { type="strings", default={} },
		commands = {
			type="strings",
			default={
				"$(CC) -c -o %{outs[1]} %{ins[1]} %{hdrpaths} %{cflags}"
			},
		}
	},
	function (e)
		local csrcs = filenamesof(e.srcs, "%.c$")
		if (#csrcs ~= 1) then
			error("you must have exactly one .c file")
		end
		
		local hsrcs = filenamesof(e.srcs, "%.h$")
		local hdeps = selectof(e.deps, "%.h$")
		local hdrpaths = {}
		for _, t in pairs(hdeps) do
			hdrpaths[#hdrpaths+1] = "-I"..t.dir
		end
		hdrpaths = uniquify(hdrpaths)

		for _, f in pairs(filenamesof(hdeps)) do
			hsrcs[#hsrcs+1] = f
		end

		local outleaf = basename(csrcs[1]):gsub("%.c$", ".o")

		return normalrule {
			name = e.name,
			ins = {csrcs[1], unpack(hsrcs)},
			outleaves = {outleaf},
			label = e.label,
			commands = e.commands,
			vars = {
				hdrpaths = hdrpaths,
				cflags = e.cflags,
			}
		}
	end
)

definerule("bundle",
	{
		srcs = { type="targets" },
		commands = {
			type="strings",
			default={
				"tar cf - %{ins} | (cd %{dir} && tar xf -)"
			}
		}
	},
	function (e)
		local outleaves = {}
		local commands = {}
		for _, f in fpairs(e.srcs) do
			local localf = basename(f)
			outleaves[#outleaves+1] = localf
			commands[#commands+1] = "cp "..f.." %{dir}/"..localf
		end

		return normalrule {
			name = e.name,
			ins = e.srcs,
			outleaves = outleaves,
			label = e.label,
			commands = commands
		}
	end
)

definerule("clibrary",
	{
		srcs = { type="targets" },
		deps = { type="targets", default={} },
		cflags = { type="strings", default={} },
		commands = {
			type="strings",
			default={
				"rm -f %{outs}",
				"$(AR) qs %{outs} %{ins}"
			},
		}
	},
	function (e)
		local csrcs = filenamesof(e.srcs, "%.c$")
		if (#csrcs < 1) then
			error("you must supply at least one C source file")
		end

		local hsrcs = filenamesof(e.srcs, "%.h$")

		local ins = {}
		for _, csrc in fpairs(csrcs) do
			local n = basename(csrc):gsub("%.%w*$", "")
			ins[#ins+1] = cfile {
				name = e.name.."/"..n,
				srcs = {csrc, unpack(hsrcs)},
				deps = e.deps,
				cflags = {
					"-I"..cwd(),
					unpack(e.cflags)
				},
			}
		end

		return normalrule {
			name = e.name,
			ins = ins,
			outleaves = { e.name..".a" },
			label = e.label,
			commands = e.commands
		}
	end
)

definerule("cprogram",
	{
		srcs = { type="targets", default={} },
		deps = { type="targets", default={} },
		commands = {
			type="strings",
			default={
				"$(CC) -o %{outs[1]} %{ins}"
			},
		}
	},
	function (e)
		local libs = filenamesof(e.deps, "%.a$")
		if (#e.srcs > 0) then
			for _, f in pairs(filenamesof(
				{
					clibrary {
						name = e.name .. "/main",
						srcs = e.srcs,
						deps = e.deps
					}
				},
				"%.a$"
			)) do
				libs[#libs+1] = f
			end
		end

		return normalrule {
			name = e.name,
			ins = libs,
			outleaves = { e.name },
			commands = e.commands,
		}
	end
)

