local function tex_escape(s)
  local map = {
    ["\\"] = "\\textbackslash{}", ["&"] = "\\&", ["%"] = "\\%",
    ["$"] = "\\$", ["#"] = "\\#", ["_"] = "\\_",
    ["{"] = "\\{", ["}"] = "\\}", ["~"] = "\\textasciitilde{}",
    ["^"] = "\\textasciicircum{}"
  }
  return (s:gsub("[\\&%%$#_{}~^]", map))
end

local function row(cells, is_header)
  local values = {}
  for _, cell in ipairs(cells) do
    local text = tex_escape(pandoc.utils.stringify(cell))
    if is_header then
      values[#values + 1] = "\\textbf{" .. text .. "}"
    else
      values[#values + 1] = text
    end
  end
  return table.concat(values, " & ") .. " \\\\ \\hline\n"
end

function Table(tbl)
  if not FORMAT:match("latex") then return tbl end
  -- Ancho total = \\linewidth (100% del ancho del texto/ventana)
  local out = {
    "\\noindent\\begin{longtable}{|>{\\centering\\arraybackslash}p{0.7cm}|p{\\dimexpr\\linewidth-3.8cm-6\\tabcolsep-4\\arrayrulewidth\\relax}|>{\\centering\\arraybackslash}p{3.1cm}|}\\hline\n"
  }
  for _, r in ipairs(tbl.head.rows) do out[#out + 1] = row(r.cells, true) end
  out[#out + 1] = "\\endfirsthead\n\\hline\n"
  for _, r in ipairs(tbl.head.rows) do out[#out + 1] = row(r.cells, true) end
  out[#out + 1] = "\\endhead\n"
  for _, body in ipairs(tbl.bodies) do
    for _, r in ipairs(body.body) do out[#out + 1] = row(r.cells, false) end
  end
  out[#out + 1] = "\\end{longtable}\n"
  return pandoc.RawBlock("latex", table.concat(out))
end
