#

hugo --theme=hugo-rapid-theme
sleep 1
mv public/ public.new
git co master
cp public.new/* . -rf
rm public.new/ -rf
git st
git add *
git st
git ci -a -m'new release'
git push
