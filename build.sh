echo "Adding..."
git add -A
echo "Committing..."
git commit -m "$1"
echo "Pushing..."
git push
echo "Done!"
