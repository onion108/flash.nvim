local Pos = require("flash.search.pos")

local M = {}

---@type ffi.namespace*
local C
local incsearch_state = {}

local function _ffi()
  if not C then
    local ffi = require("ffi")
    if vim.fn.has("nvim-0.13") then
      ffi.cdef([[
      typedef struct {
        bool hl_match;
        int32_t match_lines;
        int match_endcol;
        int32_t first_line;
        int32_t last_line;
        bool no_smartcase;
        int cmdlen;
        bool no_hlsearch;
      } SearchState;

      int no_mapping;
      SearchState Search;
      void setcursor_mayforce(bool force);
    ]])
    else
      ffi.cdef([[
      int search_match_endcol;
      int no_mapping;
      unsigned int search_match_lines;
      void setcursor_mayforce(bool force);
    ]])
    end
    C = ffi.C
  end
  return C
end

local function _get_search_match_lines()
  if vim.fn.has("nvim-0.13") then
    return C.Search.match_lines
  else
    return C.search_match_lines
  end
end

local function _set_search_match_lines(value)
  if vim.fn.has("nvim-0.13") then
    C.Search.match_lines = value
  else
    C.search_match_lines = value
  end
end

local function _get_search_match_endcol()
  if vim.fn.has("nvim-0.13") then
    return C.Search.match_endcol
  else
    return C.search_match_endcol
  end
end

local function _set_search_match_endcol(value)
  if vim.fn.has("nvim-0.13") then
    C.Search.match_endcol = value
  else
    C.search_match_endcol = value
  end
end

---@private
---@param from Pos
function M.get_end_pos(from)
  _ffi()
  local ret = Pos({
    from[1] + _get_search_match_lines(),
    math.max(0, _get_search_match_endcol() - 1),
  })
  local line = vim.api.nvim_buf_get_lines(0, ret[1] - 1, ret[1], false)[1]
  local char_idx = vim.fn.charidx(line, ret[2])
  ret[2] = vim.fn.byteidx(line, char_idx)
  return ret
end

function M.save_incsearch_state()
  _ffi()
  incsearch_state = {
    match_endcol = _get_search_match_endcol(),
    match_lines = _get_search_match_lines(),
  }
end

function M.mappings_enabled()
  _ffi()
  return C.no_mapping == 0
end

function M.setcursor(force)
  if vim.api.nvim__redraw then
    vim.api.nvim__redraw({ cursor = true })
  else
    if force == nil then
      force = false
    end
    _ffi()
    return C.setcursor_mayforce(force)
  end
end

function M.restore_incsearch_state()
  _ffi()
  _set_search_match_endcol(incsearch_state.match_endcol)
  _set_search_match_lines(incsearch_state.match_lines)
end

return M
