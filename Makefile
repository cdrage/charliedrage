convert:
	for file in img/*; do convert $$file -resize 800 $$file; done

deploy: convert
	jekyll build
	rsync -rvP _site/* root@charliedrage.com:/root/site/
	ssh root@charliedrage.com chmod -R 755 /root/site
