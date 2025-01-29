local M = {}

local note_list = {}
local user_opts = {}
local default_opts = {
	load_path = "/tmp/eznotes",
}
local MAX_INT = 2 ^ 53 - 1
local rand_seed = nil
local view_bufnr = 0
-- local log = require("eznotes.log")
function M.setup(opts)
	rand_seed = os.time()
	math.randomseed(rand_seed)
	user_opts = opts or default_opts
	if user_opts.load_path == nil then
		user_opts.load_path = default_opts.load_path
	end
	if vim.fn.isdirectory(user_opts.load_path) == 0 then
		vim.fn.mkdir(user_opts.load_path, "p")
	else
		local files = vim.fn.glob(user_opts.load_path .. "/*", false, true)
		for _, file in ipairs(files) do
			local bufnr = vim.fn.bufadd(file)
			-- vim.api.nvim_set_option_value("buftype", "nofile", { buf = bufnr })
			local note = { bufnr = bufnr, name = string.match(file, "[^/\\]+$") }
			table.insert(note_list, note)
			-- vim.notify(string.format("file added, note: %s", vim.inspect(note)))
		end
	end
	view_bufnr = vim.api.nvim_create_buf(false, true)
	if view_bufnr == 0 then
		vim.notify(string.format("Error creating buffer for view"), vim.log.levels.ERROR)
		return
	end
	vim.on_key(function(char)
		if vim.api.nvim_get_current_buf() == view_bufnr and vim.fn.keytrans(char) == "<CR>" then
			local line = vim.api.nvim_get_current_line()
			for _, note in ipairs(note_list) do
				if note.name == line then
					M.show_note(note.bufnr)
					return
				end
			end
		end
		if vim.api.nvim_get_current_buf() == view_bufnr and vim.fn.keytrans(char) == "<Esc>" then
			vim.api.nvim_win_close(0, true)
		end
	end, view_bufnr)
	local augroup = vim.api.nvim_create_augroup("eznotes", {})
	vim.api.nvim_create_autocmd("ExitPre", {
		desc = "Save notes",
		group = augroup,
		callback = function()
			-- save all notes on note_list which are still active buffers with modifications
			--
			for _, note in ipairs(note_list) do
				local bufnr = note.bufnr
				local file_name = vim.api.nvim_buf_get_name(bufnr)

				-- Avoid saving unnamed buffers
				if file_name ~= "" and vim.api.nvim_buf_is_loaded(bufnr) then
					-- Write the buffer to disk
					-- log.info("--writing buffer to disk", file_name)
					vim.api.nvim_buf_call(bufnr, function()
						vim.cmd("silent! write")
					end)
				end
			end
		end,
	})
	vim.api.nvim_create_autocmd("VimLeavePre", {
		desc = "Clears note list buffer on vim exit",
		group = augroup,
		callback = function()
			-- clear view buffer
			vim.api.nvim_buf_delete(view_bufnr, { force = true })
		end,
	})
end

function M.show_note(buf)
	local width = vim.o.columns
	local height = vim.o.lines
	local size_fraction = 0.4
	-- Define the size of the floating window
	local win_width = math.floor(width * size_fraction)
	local win_height = math.floor(height * size_fraction)

	-- Calculate the position to center the window
	local row = math.floor((height - win_height) / 2)
	local col = math.floor((width - win_width) / 2)

	vim.api.nvim_open_win(buf, true, {
		anchor = "NW",
		relative = "editor",
		width = win_width,
		height = win_height,
		row = row,
		col = col,
		border = "single",
	})
end

function M.create_note()
	local bufnr = vim.api.nvim_create_buf(false, false)
	if bufnr == 0 then
		vim.notify("Error creating buffer", vim.log.levels.ERROR)
		return
	end

	local rand = math.random(MAX_INT)
	local buf_name = string.format("%s/eznotes-%d", user_opts.load_path, rand)
	vim.api.nvim_buf_set_name(bufnr, buf_name)
	local note = { bufnr = bufnr, name = string.match(buf_name, "[^/\\]+$") }
	table.insert(note_list, note)
	M.show_note(bufnr)
end

function M.list_notes()
	local lines = {}
	for _, note in ipairs(note_list) do
		table.insert(lines, note.name)
	end

	if view_bufnr == 0 then
		vim.notify(string.format("Error creating buffer for view"), vim.log.levels.ERROR)
		return
	end

	vim.api.nvim_set_option_value("modifiable", true, { buf = view_bufnr })
	vim.api.nvim_buf_set_lines(view_bufnr, 0, -1, false, lines)
	vim.api.nvim_set_option_value("modified", false, { buf = view_bufnr })
	vim.api.nvim_set_option_value("modifiable", false, { buf = view_bufnr })
	local width = vim.o.columns
	local height = vim.o.lines
	local size_fraction = 0.2
	-- Define the size of the floating window
	local win_width = math.floor(width * size_fraction * 2)
	local win_height = math.floor(height * size_fraction * 1.5)

	-- Calculate the position to center the window
	local row = math.floor((height - win_height) / 2)
	local col = math.floor((width - win_width) / 2)

	vim.api.nvim_open_win(view_bufnr, true, {
		anchor = "NW",
		relative = "editor",
		width = win_width,
		height = win_height,
		row = row,
		col = col,
		border = "single",
	})
end

vim.api.nvim_command("command! EznotesCreateNote lua require('eznotes').create_note()")
vim.api.nvim_command("command! EznotesListNotes lua require('eznotes').list_notes()")

return M
