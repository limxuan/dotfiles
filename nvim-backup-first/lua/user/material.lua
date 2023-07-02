local status_ok, material = pcall(require, "material");

if not status_ok then
    return;
end

material.setup({})
require('material.functions').change_style("palenight")
