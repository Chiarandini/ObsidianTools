---@module 'ObsidianTools'

local M = {}


--- This is the shape of the configuration table for our plugin.
-- By defining it as a class, we get great type checking and autocompletion.
---@class ObsidianTools
---@field workspacePath string The absolute path to the workspace directory.
---@field tagListsFile string The absolute path to the tag lists file.

---@type string|nil
M.workspacePath = nil

---@type string|nil
-- M.tagListsFile = vim.fn.stdpath("data") .. "/obsidian_tag_lists.lua"
M.tagListsFile = nil

---@type table|nil
M.tagList = nil


local function read_tag_lists()
	local function try_load_file(filepath)
		local file = io.open(filepath, "r")
		if not file then
			return nil, "File not found: " .. filepath
		end
		file:close()

		local success, result = pcall(dofile, filepath)
		if not success then
			return nil, "Failed to execute file: " .. tostring(result)
		end

		if not result or type(result) ~= "table" then
			return nil, "File did not return a table"
		end

		return result
	end

	if M.tagListsFile then
		local result, err = try_load_file(M.tagListsFile)
		if result then
			return result
		else
			vim.notify("Warning: " .. err, vim.log.levels.WARN)
		end
	end

	local current_dir = debug.getinfo(1, "S").source:match("@?(.*/)")
	local default_file = (current_dir or "") .. "tag_lists.lua"

	local result, err = try_load_file(default_file)
	if result then
		print('loaded default tag table')
		return result
	else
		print("Warning: " .. err)
		print("Using minimal fallback tag lists")
		-- Minimal fallback
		return {
			["mathematics"] = { "mathematics" },
			["analysis"] = { "mathematics", "analysis" },
			["algebra"] = { "mathematics", "algebra" },
		}
	end
end


--- The main setup function for the plugin.
-- This function REQUIRES the user to provide configuration that
-- matches the shape of MyPluginOpts.
---@param opts ObsidianTools A table containing the required configuration.
function M.setup(opts)
  assert(type(opts) == 'table', "ObsidianTools requires a configuration table: require('ObsidianTools').setup({ ... })")

  assert(
    type(opts.workspacePath) == 'string' and opts.workspacePath ~= '',
    "ObsidianTools config error: 'workspacePath' is a required option and must be a non-empty string."
  )

  assert(
    type(opts.tagListsFile) == 'string' and opts.tagListsFile ~= '',
    "ObsidianTools config error: 'tagListsFile' is a required option and must be a non-empty string."
  )

  M.workspacePath = opts.workspacePath
  M.tagListsFile = opts.tagListsFile

  M.tagList = read_tag_lists()

end


--- return obsidian if it can be loaded, otherwise return nothing
---@return nil| obsidian
local function getObsidian()
	local obsidian = package.loaded["obsidian"]
	if not obsidian then
		-- Obsidian plugin is not loaded.  Try to load it.
		local status, err = pcall(require, "obsidian")
		if not status then
			vim.notify("Obsidian plugin not found: " .. (err or "Unknown error"), vim.log.levels.ERROR)
			return nil
		end
	end
	return require("obsidian") -- Assign to local variable after loading
end

--- return whether there are tags and the line on which there is a tag (or the line
--- where 'tag: []' is situated if there are no tags)
---@return boolean hasTag whether the are tags or not
---@return number position the position of the tag or tag_line
function M.hasTags()
	local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
	local tags_start_index = nil
	for i, line in ipairs(lines) do
		if string.find(line, "tags:") then
			tags_start_index = i
			break
		end
	end

	if not tags_start_index then
		error("there is no tag metadata in this markdown file")
	end

	local tag_line = vim.api.nvim_buf_get_lines(0, tags_start_index - 1, tags_start_index, false)[1]

	if string.find(tag_line, "%[%]") then
		return false, tags_start_index
	end

	-- Find the end of the tags list. Look for the first line that *doesn't* start with "-".
	for i = tags_start_index + 1, #lines do
		if string.find(lines[i], "^%-%-%-") then
			return true, i - 1
		end
	end
	error("no tags found")
end

--- Add tag to the obsidian metadata
function M.addTags()
	local hasTag, index = M.hasTags()
	if hasTag then
		vim.api.nvim_win_set_cursor(0, { index, 0 })
		vim.api.nvim_feedkeys("o- ", "n", false)
	else
		vim.api.nvim_win_set_cursor(0, { index, 0 })
		vim.api.nvim_feedkeys("$xxo  - ", "n", false)
	end
end



--- Helper function to set up common keymaps for windows
local function setup_window_keymaps(buf, callbacks)
    -- Mappings that apply to both insert and normal mode
    local shared_keys = {
        ['<CR>'] = callbacks.proceed,
        ['<C-t>'] = callbacks.tab,
        ['<C-v>'] = callbacks.vsplit,
        ['<C-c>'] = callbacks.save,
    }

    for _, mode in ipairs({ 'i', 'n' }) do
        for key, callback in pairs(shared_keys) do
            if callback then
                vim.api.nvim_buf_set_keymap(buf, mode, key, '', {
                    noremap = true,
                    silent = true,
                    callback = callback,
                })
            end
        end
    end

    -- In insert mode, <Esc> should just take us to normal mode.
    vim.api.nvim_buf_set_keymap(buf, 'i', '<Esc>', '<C-\\><C-n>', {
        noremap = true,
        silent = true,
        desc = 'Exit to normal mode',
    })

    -- In normal mode, 'q' should close the window.
    if callbacks.close then
        vim.api.nvim_buf_set_keymap(buf, 'n', 'q', '', {
            noremap = true,
            silent = true,
            callback = callbacks.close,
            desc = 'Close window',
        })
    end
end

--- Helper function to create and center a window
local function create_centered_window(width, height, title)
    local buf = vim.api.nvim_create_buf(false, true)
    local ui = vim.api.nvim_list_uis()[1]
    local col = math.floor((ui.width - width) / 2)
    local row = math.floor((ui.height - height) / 2)

    local win = vim.api.nvim_open_win(buf, true, {
        relative = 'editor',
        width = width,
        height = height,
        col = col,
        row = row,
        style = 'minimal',
        border = 'rounded',
        title = title,
        title_pos = 'center'
    })

    return buf, win
end

--- Helper function to close a window and buffer
local function close_window_and_buffer(win, buf)
    if vim.api.nvim_win_is_valid(win) then
        vim.api.nvim_win_close(win, true)
    end
    if vim.api.nvim_buf_is_valid(buf) then
        vim.api.nvim_buf_delete(buf, {force = true})
    end
end

--- Helper function to join paths properly
local function join_paths(base_path, sub_path)
    if not sub_path or sub_path == "" then
        return base_path
    end

    -- Remove trailing slash from base_path if present
    base_path = base_path:gsub("/$", "")

    -- Remove leading slash from sub_path if present
    sub_path = sub_path:gsub("^/", "")

    return base_path .. "/" .. sub_path
end

--- Common function to create the final note
local function create_note_final(filename, tags, link_text, open_cmd, subdirectory)
    local obsidian = getObsidian()
    if not obsidian then return end

    local Note = obsidian.Note
    if not Note or not Note.create then
        vim.notify("Could not find `obsidian.Note.create`. Please check your obsidian.nvim version.", vim.log.levels.ERROR)
        return
    end

    local save_path = join_paths(M.workspacePath, subdirectory)

    local note = Note.create({
        title = filename,
        dir = save_path,
        tags = tags,
    })

    if not note or not note.path or not note.path.filename then
        vim.notify("Failed to create note or note path is missing.", vim.log.levels.ERROR)
        return
    end

    if open_cmd == 'save' then
        -- Create a temporary buffer to build the file content
        local temp_buf = vim.api.nvim_create_buf(false, true) -- not listed, scratch
        note:write_to_buffer({ bufnr = temp_buf })

        if link_text then
            local lines = vim.api.nvim_buf_get_lines(temp_buf, 0, -1, false)
            for i, line in ipairs(lines) do
                if i > 1 and line:match("^---$") then
                    local link_content = {"", "[[" .. link_text .. "]]"}
                    vim.api.nvim_buf_set_lines(temp_buf, i, i, false, link_content)
                    break
                end
            end
        end

        -- Write the buffer content to the file
        local file_content = vim.api.nvim_buf_get_lines(temp_buf, 0, -1, false)
        vim.fn.writefile(file_content, note.path.filename)

        -- Clean up the temporary buffer
        vim.api.nvim_buf_delete(temp_buf, { force = true })

        vim.notify("Note saved: " .. vim.fn.fnamemodify(note.path.filename, ":t"), vim.log.levels.INFO)
        return
    end

    -- Original behavior: open the note
    local new_buf_cmd_map = {
        tab = "tabnew",
        vsplit = "vnew",
        edit = "enew"
    }
    vim.cmd(new_buf_cmd_map[open_cmd] or "enew")

    local bufnr = vim.api.nvim_get_current_buf()

    vim.api.nvim_buf_set_name(bufnr, note.path.filename)

    vim.bo[bufnr].filetype = 'markdown'

    note:write_to_buffer({ bufnr = bufnr })

    vim.notify("Note created: " .. filename, vim.log.levels.INFO)

    if link_text then
        vim.defer_fn(function()
            if vim.api.nvim_get_current_buf() ~= bufnr then
                vim.notify("Buffer changed before link could be inserted.", vim.log.levels.WARN)
                return
            end

            local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
            for i, line in ipairs(lines) do
                if i > 1 and line:match("^---$") then
                    local link_content = {"", "[[" .. link_text .. "]]"}
                    vim.api.nvim_buf_set_lines(bufnr, i, i, false, link_content)
                    break
                end
            end
        end, 100)
    end
end

--- Common function to create tags window
local function create_tags_window(filename, link_text, subdirectory)
    local tags_buf, tags_win = create_centered_window(80, 16, 'Select Tags')

    local lines = {
        "Tags: ",
        "",
        "",
        "press ENTER <cr> to create and open the file",
        "Press <c-t> to create and open the new file in a new tab",
        "Press <c-v> to create and open the file in a vertical split",
        "Press <c-c> to create and save the file without opening",
        "Press <esc> to go to normal mode, then 'q' to quit"
    }

    vim.api.nvim_buf_set_lines(tags_buf, 0, -1, false, lines)
    vim.api.nvim_win_set_cursor(tags_win, {1, #lines[1]})

    -- Set buffer options
    vim.api.nvim_buf_set_option(tags_buf, 'modifiable', true)
    vim.api.nvim_buf_set_option(tags_buf, 'buftype', 'nofile')
    vim.api.nvim_buf_set_option(tags_buf, 'filetype', 'text')

    -- Setup completion
    local cmp = require('cmp')
    local tag_source = {
        complete = function(self, params, callback)
            local items = {}
            for tag_name, tag_values in pairs(M.tagList or {}) do
                table.insert(items, {
                    label = tag_name,
                    kind = cmp.lsp.CompletionItemKind.Keyword,
                    detail = table.concat(tag_values, ", "),
                    documentation = {
                        kind = cmp.lsp.MarkupKind.PlainText,
                        value = "Tags: " .. table.concat(tag_values, ", ")
                    },
                    insertText = table.concat(tag_values, ", ")
                })
            end
            callback({ items = items })
        end,
        get_trigger_characters = function()
            return { ' ', ',' }
        end
    }

    cmp.register_source('obsidian_tags', tag_source)
    cmp.setup.buffer({
        sources = {{ name = 'obsidian_tags' }},
        -- mapping = cmp.mapping.preset.insert({
        --     ['<C-Space>'] = cmp.mapping.complete(),
        --     ['<CR>'] = cmp.mapping.confirm({ select = true }),
        --     ['<Tab>'] = cmp.mapping.select_next_item(),
        --     ['<S-Tab>'] = cmp.mapping.select_prev_item(),
        -- })
    })

    local function close_tags_window()
        close_window_and_buffer(tags_win, tags_buf)
        cmp.unregister_source('obsidian_tags')
    end

    local function create_note(open_cmd)
        local first_line = vim.api.nvim_buf_get_lines(tags_buf, 0, 1, false)[1]
        local tags_str = string.match(first_line, "Tags: (.*)")

        local unique_tags = {}

        if tags_str and tags_str ~= "" then
            local parsed_tags = vim.split(tags_str, ",")
            for _, tag in ipairs(parsed_tags) do
                tag = string.gsub(tag, "^%s*(.-)%s*$", "%1")
                tag = string.gsub(tag, " ", "_")

                if tag ~= "" then
                    unique_tags[tag] = true
                end
            end
        end

        -- Add the "link" tag to the set if it exists
        if link_text then
            unique_tags["link"] = true
        end

        -- Convert the set (keys of the table) back to a simple list
        local tags = {}
        for tag in pairs(unique_tags) do
            table.insert(tags, tag)
        end

        close_tags_window()
        create_note_final(filename, tags, link_text, open_cmd, subdirectory)
    end

    setup_window_keymaps(tags_buf, {
        proceed = function() create_note("edit") end,
        close = close_tags_window,
        tab = function() create_note("tab") end,
        vsplit = function() create_note("vsplit") end,
        save = function() create_note("save") end
    })

    vim.api.nvim_create_autocmd({"BufLeave", "WinLeave"}, {
        buffer = tags_buf,
        once = true,
        callback = close_tags_window
    })

    vim.cmd('startinsert!')
end

--- Create filename and link input window
local function create_filename_window(subdirectory)
    local buf, win = create_centered_window(80, 8, 'Create Obsidian Note')

    local save_location = join_paths(M.workspacePath or "", subdirectory)

    local lines = {
        "New markdown file name: ",
        "(optional) link: ",
        "",
        "save location: " .. save_location,
        "",
        "Press enter <cr> to continue and choose tags",
        "Press <esc> to go to normal mode, then 'q' to quit"
    }

    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.api.nvim_win_set_cursor(win, {1, #lines[1]})

    vim.api.nvim_buf_set_option(buf, 'modifiable', true)
    vim.api.nvim_buf_set_option(buf, 'buftype', 'nofile')

    local function close_window()
        close_window_and_buffer(win, buf)
    end

    local function proceed_to_tags()
        local buffer_lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)

        -- Extract filename from first line
        local filename = string.match(buffer_lines[1], "New markdown file name: (.*)")
        if not filename or filename == "" then
            vim.notify("Please enter a filename", vim.log.levels.ERROR)
            return
        end

        -- Extract link from second line (optional)
        local link_text = string.match(buffer_lines[2], "%(optional%) link: (.*)")
        if link_text and link_text == "" then
            link_text = nil
        end

        close_window()
        create_tags_window(filename, link_text, subdirectory)
    end

    setup_window_keymaps(buf, {
        proceed = proceed_to_tags,
        close = close_window
    })

    vim.api.nvim_create_autocmd({"BufLeave", "WinLeave"}, {
        buffer = buf,
        once = true,
        callback = close_window
    })

    vim.cmd('startinsert!')
end

--- Create a new obsidian note with optional link and subdirectory
---@param subdirectory string|nil Optional subdirectory path to append to workspacePath
function M.create_obsidian_note(subdirectory)
    local obsidian = getObsidian()
    if not obsidian then return end

    create_filename_window(subdirectory)
end



--- Return a telescope picker that allows you to add tags to your obsidian markdown file
---@param tag_lists Object list of entries and tags
function M.addTagsFromList(tag_lists)
	local telescope = require("telescope")
	local pickers = require("telescope.pickers")
	local actions = require("telescope.actions")
	local action_state = require("telescope.actions.state")
	local finders = require("telescope.finders")
	local config = require("telescope.config")
	local previewers = require("telescope.previewers")
	local sorters = require("telescope.sorters")


	--- Adds the selected tags to the current document
	---@param prompt_bufnr number The telescope prompt buffer number
	---@param original_bufnr number The buffer number of the document being edited
	local function add_tags(prompt_bufnr, original_bufnr)
		local selection = action_state.get_selected_entry()
		if not selection or not selection.value then
			return -- Nothing selected
		end

		local tags_to_add = tag_lists[selection.value]
		if not tags_to_add then
			return -- Selected entry has no associated tags.
		end

		-- Remove duplicates from tags_to_add
		local unique_tags = {}
		local unique_tags_list = {}
		for _, tag in ipairs(tags_to_add) do
			if not unique_tags[tag] then
				unique_tags[tag] = true
				table.insert(unique_tags_list, tag)
			end
		end
		tags_to_add = unique_tags_list

		-- Get existing tags
		local existing_tags = {}
		local start_line = -1
		local end_line = -1
		local in_tags_section = false

		for i, line in ipairs(vim.api.nvim_buf_get_lines(original_bufnr, 0, -1, false)) do
			local trimmed_line = string.gsub(line, "%s+", "") -- Remove all whitespace
			if trimmed_line == "tags:[]" then
				-- Handle "tags: []" case
				local line_number = i
				vim.api.nvim_buf_set_lines(original_bufnr, line_number - 1, line_number, false, { "tags:" })
				start_line = i
				in_tags_section = true
			elseif trimmed_line == "tags:" then
				start_line = i
				in_tags_section = true
			elseif in_tags_section then
				if string.sub(trimmed_line, 1, 3) == "---" then
					end_line = i - 1
					break
				elseif string.sub(line, 1, 3) == "  -" then
					local tag = string.match(line, "^%s*-%s*(.*)")
					if tag then
						existing_tags[tag] = true
					end
				else
					end_line = i - 1
					break
				end
			end
		end

		-- If no existing tags section, create one.
		if start_line == -1 then
			-- Find the line with "---" before the id/aliases
			local insert_before_line = nil
			for i, line in ipairs(vim.api.nvim_buf_get_lines(original_bufnr, 0, -1, false)) do
				local trimmed_line = string.gsub(line, "%s+", "")
				if trimmed_line == "id:" or trimmed_line == "aliases:" then -- Found id or aliases
					insert_before_line = i
					break
				end
			end
			if insert_before_line == nil then
				-- Insert at the end of the buffer if we didn't find an id or aliases
				insert_before_line = #vim.api.nvim_buf_get_lines(original_bufnr, 0, -1, false) + 1
			end

			-- Create tags section
			local new_tag_lines = { "tags:" }
			for _, tag in ipairs(tags_to_add) do
				table.insert(new_tag_lines, "  - " .. tag)
			end

			vim.api.nvim_buf_set_lines(
				original_bufnr,
				insert_before_line - 1,
				insert_before_line - 1,
				false,
				new_tag_lines
			)
			actions.close(prompt_bufnr)
			return
		end

		-- Determine insertion point (after the last existing tag).
		local insert_line = end_line
		if insert_line == -1 then
			insert_line = start_line
		end

		-- Create the new tag lines, filtering out duplicates.
		local new_tag_lines = {}
		for _, tag in ipairs(tags_to_add) do
			if not existing_tags[tag] then
				table.insert(new_tag_lines, "  - " .. tag)
			end
		end

		-- Insert the new tag lines.
		vim.api.nvim_buf_set_lines(original_bufnr, insert_line, insert_line, false, new_tag_lines)
		actions.close(prompt_bufnr)
	end

	--- Displays a preview of the tags that will be added
	---@param self table The previewer object
	---@param entry table The selected entry
	---@param status table The status of the picker
	local function define_preview(self, entry, status)
		if not entry or not entry.value then
			vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, { "No entry selected." })
			return
		end

		local tags = tag_lists[entry.value]
		if tags then
			local new_tag_lines = {}
			for _, tag in ipairs(tags) do
				table.insert(new_tag_lines, "  - " .. tag)
			end
			vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, new_tag_lines)
		else
			vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, { "No tags defined for this list." })
		end
	end

	local my_buffer_previewer = previewers.new_buffer_previewer({
		define_preview = define_preview,
		-- setup = function(self) end, -- Optional setup
		-- teardown = function(self) end, -- Optional teardown
		title = "Tag Preview",
	})

	local original_bufnr = vim.api.nvim_get_current_buf()

	pickers
		.new({}, {
			prompt_title = "Add Tags",
			-- Display the keys of the tag_lists table in Telescope.
			finder = finders.new_table({
				results = vim.tbl_keys(tag_lists),
				displayer = {
					-- This is a minimal displayer; you might want to customize it further.
					-- For example, you could add icons or color.
					transform = function(entry)
						return entry
					end,
					width = function()
						return 80 -- Or whatever width you want
					end,
				},
			}),
			sorter = require("telescope.sorters").get_fzy_sorter({}),
			attach_mappings = function(_, map)
				map("i", "<CR>", function(prompt_bufnr)
					add_tags(prompt_bufnr, original_bufnr)
				end)
				map("n", "<CR>", function(prompt_bufnr)
					add_tags(prompt_bufnr, original_bufnr)
				end)
				return true
			end,
			-- Use the buffer previewer.
			previewer = my_buffer_previewer,
		})
		:find()
end



-- Function to extract hashtags from a line
local function extract_hashtags(line)
    local hashtags = {}

    -- Match # followed by any characters until next # or end of line
    for hashtag in string.gmatch(line, "#([^#\\n]+)") do
        -- Trim whitespace from both ends
        local cleaned_tag = hashtag:gsub("^%s*", ""):gsub("%s*$", "")

        -- Replace spaces with underscores
        cleaned_tag = cleaned_tag:gsub("%s+", "_")

        -- Only add if not empty after cleaning
        if cleaned_tag ~= "" then
            table.insert(hashtags, cleaned_tag)
        end
    end

    return hashtags
end

-- Function to check if a line is blank or whitespace only
local function is_blank_line(line)
    return line:match("^%s*$") ~= nil
end

-- Function to process a single markdown file
local function process_markdown_file(filepath)
    -- Read the file
    local lines = vim.fn.readfile(filepath)

    if #lines == 0 then
        return "skip", {}, ""
    end

    -- Check if file already has frontmatter
    if lines[1]:match("^---") then
        return "skip", {}, ""
    end

    -- Find first non-blank line and check for hashtags
    local hashtag_line_index = nil
    local hashtags = {}
    local original_line = ""

    for i = 1, math.min(#lines, 10) do -- Check first 10 lines max
        local line = lines[i]

        if not is_blank_line(line) then
            -- This is the first non-blank line
            hashtags = extract_hashtags(line)

            if #hashtags > 0 then
                hashtag_line_index = i
                original_line = line
                break
            else
                -- First non-blank line doesn't have hashtags
                return "no_tags", {}, ""
            end
        end
    end

    -- If no hashtags found in first non-blank line
    if not hashtag_line_index or #hashtags == 0 then
        return "no_tags", {}, ""
    end

    -- Get filename without extension for the id
    local filename = vim.fn.fnamemodify(filepath, ":t:r")

    -- Create frontmatter
    local frontmatter = {
        "---",
        "id: " .. filename,
        "aliases: []",
        "tags:"
    }

    -- Add each tag
    for _, tag in ipairs(hashtags) do
        table.insert(frontmatter, "  - " .. tag)
    end

    table.insert(frontmatter, "---")

    -- Create new content (remove the line with hashtags)
    local new_content = {}

    -- Add frontmatter
    for _, line in ipairs(frontmatter) do
        table.insert(new_content, line)
    end

    -- Add remaining content (skip the line with hashtags)
    for i = 1, #lines do
        if i ~= hashtag_line_index then
            table.insert(new_content, lines[i])
        end
    end

    -- Write back to file
    vim.fn.writefile(new_content, filepath)

    -- Print only the filename (not full path)
    local file_display_name = vim.fn.fnamemodify(filepath, ":t")
    print("✓ " .. file_display_name)

    return "success", hashtags, original_line
end

-- Function to open Trouble with the results
local function open_trouble_results(quickfix_entries)
    local trouble_ok, trouble = pcall(require, "trouble")

    if not trouble_ok then
        print("Trouble plugin not found. Install folke/trouble.nvim to use this feature.")
        print("Falling back to native quickfix list.")
        vim.fn.setqflist(quickfix_entries, 'r')
        vim.cmd("copen")
        return
    end

    -- Set the quickfix list (Trouble reads from this)
    vim.fn.setqflist(quickfix_entries, 'r')

    -- Open Trouble with quickfix results
    trouble.open("quickfix")

    print("Opened results in Trouble. Use <CR> to jump to files.")
end

-- Function to process all markdown files in a directory
local function process_directory(directory_path)
    -- Expand path
    local expanded_path = vim.fn.expand(directory_path)

    -- Check if directory exists
    if vim.fn.isdirectory(expanded_path) == 0 then
        print("Error: Directory '" .. directory_path .. "' does not exist")
        return
    end

    -- Find all .md files
    local md_files = vim.fn.glob(expanded_path .. "/*.md", false, true)

    if #md_files == 0 then
        print("No markdown files found in '" .. expanded_path .. "'")
        return
    end

    print("Found " .. #md_files .. " markdown files")
    print("Modified files:")

    local processed_count = 0
    local no_tags_count = 0
    local quickfix_entries = {}

    for _, filepath in ipairs(md_files) do
        local status, hashtags, original_line = process_markdown_file(filepath)

        if status == "success" then
            processed_count = processed_count + 1

            -- Add to quickfix list with original line
            table.insert(quickfix_entries, {
                filename = filepath,
                lnum = 1,
                text = "original: " .. original_line
            })
        elseif status == "no_tags" then
            no_tags_count = no_tags_count + 1

            -- Add to quickfix list as no tags found
            table.insert(quickfix_entries, {
                filename = filepath,
                lnum = 1,
                text = "no tags found"
            })
        end
        -- "skip" status (files with frontmatter) are not added to quickfix
    end

    print("\\nProcessed " .. processed_count .. " out of " .. #md_files .. " files")
    if no_tags_count > 0 then
        print(no_tags_count .. " files found with no tags")
    end

    -- Automatically open Trouble with results if we have any entries
    if #quickfix_entries > 0 then
        print("Total " .. #quickfix_entries .. " files in results")
        open_trouble_results(quickfix_entries)
    end
end

function M.convert_hashtags()
    vim.ui.input({ prompt = "Enter directory path (or press Enter for current): " }, function(directory)
        -- User pressed <Esc>
        if not directory then
            print("Operation cancelled.")
            return
        end

        if directory == "" then
            directory = "."
        end

        print("\\nProcessing directory: " .. vim.fn.fnamemodify(directory, ":p"))

        vim.ui.input({ prompt = "Proceed? This will modify your files. (y/N): " }, function(confirm)
            if not confirm or confirm:lower() ~= 'y' and confirm:lower() ~= 'yes' then
                print("Operation cancelled.")
                return
            end

            process_directory(directory)
        end)
    end)
end



return M
