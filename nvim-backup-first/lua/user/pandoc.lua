local status_ok, pandoc = pcall(require, "pandoc")
if not status_ok then
	return
end
pandoc.setup({
  default = {
    args = {
      { '--standalone' },
      { '--pdf-engine', 'pdflatex' },
    },
   },
})
