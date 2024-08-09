local augroup = vim.api.nvim_create_augroup("TrackMe", { clear = true })

local floating_win_id = nil
local file_open_counts = {}
local is_toggling = false

local function window_config(width, height)
	local win_width = math.floor(width * 0.4)
	local win_height = math.floor(height * 0.2)

	local row = math.floor((vim.o.lines - win_height) / 2)
	local col = math.floor((vim.o.columns - win_width) / 2)

	local border = vim.g.workbench_border or "double"

	return {
		relative = "editor",
		width = win_width,
		height = win_height,
		row = row,
		col = col,
		style = "minimal",
		focusable = false,
		border = border,
	}
end

local function update_floating_window_content(buf)
	local lines = {}

	-- Convert the file_open_counts table to a sortable list
	local sorted_files = {}
	for filename, count in pairs(file_open_counts) do
		table.insert(sorted_files, { filename = filename, count = count })
	end

	-- Sort the list by the count, in descending order
	table.sort(sorted_files, function(a, b)
		return a.count > b.count
	end)

	-- Prepare the lines for the buffer
	for _, entry in ipairs(sorted_files) do
		table.insert(lines, entry.filename .. " - Opened " .. entry.count .. " times")
	end

	-- Update the buffer with sorted lines
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
end

local function toggle_floating_window()
	is_toggling = true

	if floating_win_id and vim.api.nvim_win_is_valid(floating_win_id) then
		vim.api.nvim_win_close(floating_win_id, true)
		floating_win_id = nil
	else
		local ui = vim.api.nvim_list_uis()[1]
		local buf = vim.api.nvim_create_buf(false, true) -- Create a new buffer
		floating_win_id = vim.api.nvim_open_win(buf, true, window_config(ui.width, ui.height))
		update_floating_window_content(buf) -- Populate the window with initial content
	end

	is_toggling = false
end

local function on_buf_enter()
	if not is_toggling then
		local buf_name = vim.api.nvim_buf_get_name(0)

		local file_name = vim.fn.fnamemodify(buf_name, ":t")

		-- Increment the open count for the current file
		if file_open_counts[file_name] then
			file_open_counts[file_name] = file_open_counts[file_name] + 1
		else
			file_open_counts[file_name] = 1
		end

		-- If the floating window is open, update its content
		if floating_win_id and vim.api.nvim_win_is_valid(floating_win_id) then
			local buf = vim.api.nvim_win_get_buf(floating_win_id)
			update_floating_window_content(buf)
		end
	end
end

local function setup()
	vim.keymap.set("n", "<Leader>t", toggle_floating_window)

	vim.api.nvim_create_autocmd("BufEnter", {
		group = augroup,
		desc = "Tracking how many times files are opened",
		once = false,
		callback = on_buf_enter,
	})
end

return { setup = setup }
