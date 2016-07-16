SITE ?= 198.52.161.115

convert:
	for file in img/*; do convert $$file -resize 800 $$file; done

deploy: convert
	jekyll build
	rsync -rvP _site/* core@$(SITE):/home/core/html
	ssh core@$(SITE) chmod -R 755 /home/core/html
