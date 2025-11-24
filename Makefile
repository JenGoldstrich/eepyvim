install:
	mkdir -p ~/.config/nvim
	cp * ~/.config/nvim/
	nvim --headless -c "lua require('lazy').sync()" -c "qa"
