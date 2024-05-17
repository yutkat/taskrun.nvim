local M = {}
local config = {
	size = vim.fn.float2nr(vim.o.lines * 0.25),
	notify_timeout = 1000,
}
local notify = vim.F.npcall(require, "notify")

local terminal = require("toggleterm.terminal").Terminal
local task_runner = terminal:new({ direction = "horizontal", count = 9 })
local last_cmd = ""

local function notification(message, level)
	local title = "TaskRun"

	if notify then
		notify(message, level, {
			title = title,
			timeout = config.notify_timeout,
		})
	else
		-- vim.notify(("[%s] %s"):format(title, message), level)
	end
end

local function get_exit_status()
	local bufnr = task_runner.bufnr
	local ln = vim.api.nvim_buf_line_count(bufnr)
	while ln >= 1 do
		local l = vim.api.nvim_buf_get_lines(bufnr, ln - 1, ln, true)[1]
		ln = ln - 1
		local exit_code = string.match(l, "^%[Process exited ([0-9]+)%]$")
		if exit_code ~= nil then
			return tonumber(exit_code)
		end
	end
end

local function send_notify()
	if task_runner == nil or task_runner.bufnr == nil then
		return
	end
	print(task_runner.bufnr)
	if vim.api.nvim_buf_is_valid(task_runner.bufnr) then
		local result = get_exit_status()
		if result == nil then
			return "Finished"
		elseif result == 0 then
			notification("Success", vim.log.levels.INFO)
			return "Success"
		elseif result >= 1 then
			notification("Error", vim.log.levels.WARN)
			return "Error"
		end
		return "Finished"
	end
	return "Command"
end

function M.notify()
	local timer = vim.uv.new_timer()
	-- Because "Process exited" message is not displayed immediately after TermClose
	timer:start(100, 0, vim.schedule_wrap(send_notify))
end

function M.run(cmd)
	if task_runner:is_open() then
		task_runner:shutdown()
	end
	last_cmd = cmd
	task_runner = terminal:new({ cmd = cmd, direction = "horizontal", count = 9 })
	task_runner:open(config.size, "horizontal", true)
	-- require('toggleterm.ui').save_window_size()
	vim.cmd([[let g:toglleterm_win_num = winnr()]])
	vim.cmd([[setlocal number]])
	vim.cmd([[stopinsert | wincmd p]])
end

function M.run_last()
	if last_cmd == "" then
		print("Please start TaskRun with arguments")
		return
	end
	M.run(last_cmd)
end

function M.toggle()
	task_runner:toggle(config.size)
	if task_runner:is_open() then
		vim.cmd("wincmd p")
	end
end

local function toggle_term_shutdown()
	if task_runner:is_open() then
		task_runner:shutdown()
	end
end

function M.close()
	toggle_term_shutdown()
	if vim.api.nvim_win_is_valid(vim.g.toglleterm_win_num) then
		vim.api.nvim_win_close(vim.g.toglleterm_win_num)
	end
end

local function create_commands()
	vim.api.nvim_create_user_command("TaskRun", "lua require('taskrun').run(<q-args>)", { force = true, nargs = "+" })
	vim.api.nvim_create_user_command("TaskRunToggle", "lua require('taskrun').toggle()", { force = true, nargs = 0 })
	vim.api.nvim_create_user_command("TaskRunLast", "lua require('taskrun').run_last()", { force = true, nargs = 0 })
end

local function create_autocmds()
	local group_name = "taskrun"
	vim.api.nvim_create_augroup(group_name, { clear = true })
	vim.api.nvim_create_autocmd({ "TermClose" }, {
		group = group_name,
		pattern = "term://*#toggleterm#9*",
		callback = function()
			if vim.fn.winbufnr(vim.g.toglleterm_win_num) ~= -1 then
				vim.cmd(vim.g.toglleterm_win_num .. "wincmd w")
				vim.cmd("$")
				vim.cmd("wincmd p")
			end
		end,
		once = false,
		nested = true,
	})
	vim.api.nvim_create_autocmd({ "TermClose" }, {
		group = group_name,
		pattern = "term://*#toggleterm#9*",
		callback = function()
			require("taskrun").notify()
		end,
		once = false,
		nested = true,
	})
end

function M.setup(opts)
	opts = opts or {}
	config = vim.tbl_deep_extend("keep", opts, config)
	create_commands()
	create_autocmds()
end

return M
